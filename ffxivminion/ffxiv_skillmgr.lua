﻿-- Skillmanager for adv. skill customization
SkillMgr = {}
SkillMgr.version = "v2.0";
SkillMgr.lastTick = 0
SkillMgr.ConditionList = {}
SkillMgr.CurrentSkill = {}
SkillMgr.CurrentSkillData = {}
SkillMgr.CurrentTarget = {}
SkillMgr.CurrentTID = 0
SkillMgr.CurrentPet = {}
SkillMgr.profilepath = GetStartupPath() .. [[\LuaMods\ffxivminion\SkillManagerProfiles\]];
SkillMgr.skillbook = { name = GetString("skillbook"), x = 250, y = 50, w = 250, h = 350}
SkillMgr.mainwindow = { name = GetString("skillManager"), x = 350, y = 50, w = 250, h = 350}
SkillMgr.editwindow = { name = GetString("skillEditor"), x = 250, y = 50, w = 250, h = 550}
SkillMgr.editwindow_crafting = { name = GetString("skillEditor_craft"), x = 250, y = 50, w = 250, h = 550}
SkillMgr.editwindow_gathering = { name = GetString("skillEditor_gather"), x = 250, y = 50, w = 250, h = 550}
SkillMgr.confirmwindow = { name = GetString("confirm"), x = 250, y = 50, w = 250, h = 120}
SkillMgr.SkillBook = {}
SkillMgr.SkillProfile = {}
SkillMgr.lastQueued = 0
SkillMgr.queuedPrio = 0
SkillMgr.currentChain = ""
SkillMgr.prevSkillID = ""
SkillMgr.prevSkillTimestamp = 0
SkillMgr.prevGCDSkillID = ""
SkillMgr.prevSkillList = {}
SkillMgr.nextSkillID = ""
SkillMgr.nextSkillPrio = ""
SkillMgr.failTimer = 0
SkillMgr.teleCastTimer = 0
SkillMgr.teleBack = {}
SkillMgr.copiedSkill = {}

SkillMgr.bestAOE = 0
SkillMgr.lastCast = 0
SkillMgr.comboQueue = {}
SkillMgr.otherQueue = {}
SkillMgr.latencyTimer = 0
SkillMgr.forceStop = false
SkillMgr.preCombat = false
SkillMgr.knownDebuffs = "1,610,4,5,6,213,620,7,9,10,193,442,561,193,280,564,14,240,15,571,17,216,482,677,​407,18,559,560,686,801,275,19,20,26,28,30,32,34,36,38,54,55,58,59,62,63,66,67,18​1,250,267,284,530,619,503,268,285,535,605,235,269,286,532,270,287,534,271,288,53​3,666,272,283,485,273,320,339,343,642,643,509,210,910,3,926,215"
--SkillMgr.logger = logging.rolling_file(GetStartupPath()..[[\LuaMods\ffxivminion\logs\]].."skm.log", 102400, 5)

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
}

SkillMgr.StartingProfiles = {
	[FFXIV.JOBS.GLADIATOR] = "Gladiator",
	[FFXIV.JOBS.PALADIN] = "Paladin",
    [FFXIV.JOBS.MARAUDER] = "Marauder",
	[FFXIV.JOBS.WARRIOR] = "Warrior",
	[FFXIV.JOBS.PUGILIST] = "Monk",
	[FFXIV.JOBS.MONK] = "Monk",
	[FFXIV.JOBS.LANCER] = "Lancer",
	[FFXIV.JOBS.DRAGOON] = "Dragoon",
	[FFXIV.JOBS.ARCHER] = "Archer",
	[FFXIV.JOBS.BARD] = "Bard",
	[FFXIV.JOBS.CONJURER] = "Conjurer",
	[FFXIV.JOBS.WHITEMAGE] = "White_Mage",
	[FFXIV.JOBS.THAUMATURGE] = "Black_Mage",
	[FFXIV.JOBS.BLACKMAGE] = "Black_Mage",
	[FFXIV.JOBS.ARCANIST] = "Arcanist",
	[FFXIV.JOBS.SUMMONER] = "Summoner",
	[FFXIV.JOBS.SCHOLAR] = "Scholar",
	[FFXIV.JOBS.BOTANIST] = "Botanist",
	[FFXIV.JOBS.MINER] = "Miner",
	[FFXIV.JOBS.CULINARIAN] = "Culinarian",
	[FFXIV.JOBS.ROGUE] = "Rogue",
	[FFXIV.JOBS.NINJA] = "Ninja",
	[FFXIV.JOBS.MACHINIST] = "Machinist",
	[FFXIV.JOBS.ASTROLOGIAN] = "Astrologian",
	[FFXIV.JOBS.DARKKNIGHT] = "DarkKnight",
}

SkillMgr.ActionTypes = {
	ACTIONS = 1,
	CRAFT = 9,
	PET = 11,
}

SkillMgr.Variables = {
	SKM_NAME = { default = "", cast = "string", profile = "name", section = "main"},
	SKM_ALIAS = { default = "", cast = "string", profile = "alias", section = "main"},
	SKM_ID = { default = 0, cast = "number", profile = "id", section = "main"},
	SKM_TYPE = { default = 1, cast = "number", profile = "type", section = "main", useData = "type" },
	SKM_ON = { default = "0", cast = "string", profile = "used", section = "main"},
	SKM_Prio = { default = 0, cast = "number", profile = "prio", section = "main"},
	
	SKM_STYPE = { default = "Action", cast = "string", profile = "stype", section = "fighting"},
	SKM_CHARGE = { default = "0", cast = "string", profile = "charge", section = "fighting" },
	SKM_DOBUFF = { default = "0", cast = "string", profile = "dobuff", section = "fighting" },
	SKM_REMOVESBUFF = { default = "0", cast = "string", profile = "removebuff", section = "fighting" },
	SKM_DOPREV = { default = "0", cast = "string", profile = "doprev", section = "fighting"  },
	SKM_LevelMin = { default = 0, cast = "number", profile = "levelmin", section = "fighting", useData = "level" },
	SKM_LevelMax = { default = 0, cast = "number", profile = "levelmax", section = "fighting"   },
	SKM_Combat = { default = "In Combat", cast = "string", profile = "combat", section = "fighting"  },
	SKM_PVEPVP = { default = "Both", cast = "string", profile = "pvepvp", section = "fighting" },
	SKM_OnlySolo = { default = "0", cast = "string", profile = "onlysolo", section = "fighting"  },
	SKM_OnlyParty = { default = "0", cast = "string", profile = "onlyparty", section = "fighting"  },
	SKM_FilterOne = { default = "Ignore", cast = "string", profile = "filterone", section = "fighting"  },
	SKM_FilterTwo = { default = "Ignore", cast = "string", profile = "filtertwo", section = "fighting"  },
	SKM_FilterThree = { default = "Ignore", cast = "string", profile = "filterthree", section = "fighting"  },
	SKM_FilterFour = { default = "Ignore", cast = "string", profile = "filterfour", section = "fighting"  },
	SKM_FilterFive = { default = "Ignore", cast = "string", profile = "filterfive", section = "fighting"  },
	SKM_ComboSkill = { default = "Auto", cast = "string", profile = "comboskill", section = "fighting"  },
	--SKM_MPLock = { default = "0", cast = "string", profile = "mplock", section = "fighting" },
	--SKM_MPLocked = { default = "0", cast = "string", profile = "mplocked", section = "fighting" },
	--SKM_MPLockPer = { default = 0, cast = "number", profile = "mplockper", section = "fighting" },
	SKM_TRG = { default = GetString("target"), cast = "string", profile = "trg", section = "fighting"  },
	SKM_TRGTYPE = { default = "Any", cast = "string", profile = "trgtype", section = "fighting"  },
	SKM_NPC = { default = "0", cast = "string", profile = "npc", section = "fighting"  },
	SKM_PTRG = { default = "Any", cast = "string", profile = "ptrg", section = "fighting" },
	SKM_PGTRG = { default = "Direct", cast = "string", profile = "pgtrg", section = "fighting"  },
	SKM_HPRIOHP = { default = 0, cast = "number", profile = "hpriohp", section = "fighting"  },
	SKM_HPRIO1 = { default = "None", cast = "string", profile = "hprio1", section = "fighting"  },
	SKM_HPRIO2 = { default = "None", cast = "string", profile = "hprio2", section = "fighting"  },
	SKM_HPRIO3 = { default = "None", cast = "string", profile = "hprio3", section = "fighting"  },
	SKM_HPRIO4 = { default = "None", cast = "string", profile = "hprio4", section = "fighting"  },
	SKM_MinR = { default = 0, cast = "number", profile = "minRange", section = "fighting"  },
	SKM_MaxR = { default = 24, cast = "number", profile = "maxRange", section = "fighting", useData = "range" },
	SKM_PHPL = { default = 0, cast = "number", profile = "phpl", section = "fighting"   },
	SKM_PHPB = { default = 0, cast = "number", profile = "phpb", section = "fighting"   },
	SKM_PUnderAttack = { default = "0", cast = "string", profile = "punderattack", section = "fighting"  },
	SKM_PUnderAttackMelee = { default = "0", cast = "string", profile = "punderattackmelee", section = "fighting"  },
	SKM_PPowL = { default = 0, cast = "number", profile = "ppowl", section = "fighting"   },
	SKM_PPowB = { default = 0, cast = "number", profile = "ppowb", section = "fighting"   },
	SKM_PMPPL = { default = 0, cast = "number", profile = "pmppl", section = "fighting"   },
	SKM_PMPPB = { default = 0, cast = "number", profile = "pmppb", section = "fighting"   },
	SKM_PTPL = { default = 0, cast = "number", profile = "ptpl", section = "fighting"  },
	SKM_PTPB = { default = 0, cast = "number", profile = "ptpb", section = "fighting"  },
	SKM_THPL = { default = 0, cast = "number", profile = "thpl", section = "fighting"  },
	SKM_THPB = { default = 0, cast = "number", profile = "thpb", section = "fighting"  },
	SKM_THPADV = { default = 0, cast = "number", profile = "thpadv", section = "fighting"  },
	SKM_TTPL = { default = 0, cast = "number", profile = "ttpl", section = "fighting"  },
	SKM_TMPL = { default = 0, cast = "number", profile = "tmpl", section = "fighting"  },
	SKM_PTCount = { default = 0, cast = "number", profile = "ptcount", section = "fighting"   },
	SKM_PTHPL = { default = 0, cast = "number", profile = "pthpl", section = "fighting"   },
	SKM_PTHPB = { default = 0, cast = "number", profile = "pthpb", section = "fighting"   },
	SKM_PTMPL = { default = 0, cast = "number", profile = "ptmpl", section = "fighting"   },
	SKM_PTMPB = { default = 0, cast = "number", profile = "ptmpb", section = "fighting"   },
	SKM_PTTPL = { default = 0, cast = "number", profile = "pttpl", section = "fighting"   },
	SKM_PTTPB = { default = 0, cast = "number", profile = "pttpb", section = "fighting"   },
	SKM_PTBuff = { default = "", cast = "string", profile = "ptbuff", section = "fighting"  },
	SKM_PTKBuff = { default = "0", cast = "string", profile = "ptkbuff", section = "fighting"  },
	SKM_PTNBuff = { default = "", cast = "string", profile = "ptnbuff", section = "fighting"  },
	SKM_THPCL = { default = 0, cast = "number", profile = "thpcl", section = "fighting"   },
	SKM_THPCB = { default = 0, cast = "number", profile = "thpcb", section = "fighting"   },
	SKM_TCONTIDS = { default = "", cast = "string", profile = "tcontids", section = "fighting"  },
	SKM_TNCONTIDS = { default = "", cast = "string", profile = "tncontids", section = "fighting"  },
	SKM_TCASTID = { default = "", cast = "string", profile = "tcastids", section = "fighting"  },
	SKM_TCASTTM = { default = "0", cast = "string", profile = "tcastonme", section = "fighting"  },
	SKM_TCASTTIME = { default = "0.0", cast = "string", profile = "tcasttime", section = "fighting"  },
	SKM_TECount = { default = 0, cast = "number", profile = "tecount", section = "fighting"   },
	SKM_TECount2 = { default = 0, cast = "number", profile = "tecount2", section = "fighting"   },
	
	SKM_EnmityAOE = { default = "0", cast = "string", profile = "enmityaoe", section = "fighting"   },
	SKM_FrontalConeAOE = { default = "0", cast = "string", profile = "frontalconeaoe", section = "fighting"   },
	SKM_TankedOnly = { default = "0", cast = "string", profile = "tankedonlyaoe", section = "fighting"   },
	
	SKM_TERange = { default = 0, cast = "number", profile = "terange", section = "fighting" , useData = "radius" },
	SKM_TECenter = { default = "Auto", cast = "string", profile = "tecenter", section = "fighting"  },
	SKM_TELevel = { default = "Any", cast = "string", profile = "televel", section = "fighting"  },
	SKM_TACount = { default = 0, cast = "number", profile = "tacount", section = "fighting"   },
	SKM_TARange = { default = 0, cast = "number", profile = "tarange", section = "fighting", useData = "radius" },
	SKM_TAHPL = { default = 0, cast = "number", profile = "tahpl", section = "fighting"   },
	SKM_PBuff = { default = "", cast = "string", profile = "pbuff", section = "fighting"  },
	SKM_PBuffDura = { default = 0, cast = "number", profile = "pbuffdura", section = "fighting" },
	SKM_PNBuff = { default = "", cast = "string", profile = "pnbuff", section = "fighting"  },
	SKM_PNBuffDura = { default = 0, cast = "number", profile = "pnbuffdura", section = "fighting"   },
	SKM_TBuffOwner = { default = "Player", cast = "string", profile = "tbuffowner", section = "fighting"  },
	SKM_TBuff = { default = "", cast = "string", profile = "tbuff", section = "fighting"  },
	SKM_TBuffDura = { default = 0, cast = "number", profile = "tbuffdura", section = "fighting"   },
	SKM_TNBuff = { default = "", cast = "string", profile = "tnbuff", section = "fighting"  },
	SKM_TNBuffDura = { default = 0, cast = "number", profile = "tnbuffdura", section = "fighting"   },
	
	SKM_PetBuff = { default = "", cast = "string", profile = "petbuff", section = "fighting"  },
	SKM_PetBuffDura = { default = 0, cast = "number", profile = "petbuffdura", section = "fighting" },
	SKM_PetNBuff = { default = "", cast = "string", profile = "petnbuff", section = "fighting"  },
	SKM_PetNBuffDura = { default = 0, cast = "number", profile = "petnbuffdura", section = "fighting"   },
	
	SKM_PSkillID = { default = "", cast = "string", profile = "pskill", section = "fighting"  },
	SKM_NPSkillID = { default = "", cast = "string", profile = "npskill", section = "fighting"  },
	SKM_PCSkillID = { default = "", cast = "string", profile = "pcskill", section = "fighting"  },
	SKM_NPCSkillID = { default = "", cast = "string", profile = "npcskill", section = "fighting"  },
	SKM_PGSkillID = { default = "", cast = "string", profile = "pgskill", section = "fighting"  },
	SKM_NPGSkillID = { default = "", cast = "string", profile = "npgskill", section = "fighting"  },
	--SKM_NSkillID = { default = "", cast = "string", profile = "nskill", section = "fighting"  },
	--SKM_NSkillPrio = { default = "", cast = "string", profile = "nskillprio", section = "fighting"  },
	
	SKM_SecsPassed = { default = 0, cast = "number", profile = "secspassed", section = "fighting"   },
	SKM_PPos = { default = "None", cast = "string", profile = "ppos", section = "fighting" },
	SKM_OffGCD = { default = "Auto", cast = "string", profile = "gcd", section = "fighting" },
	SKM_OffGCDTime = { default = .5, cast = "number", profile = "gcdtime", section = "fighting" },
	SKM_OffGCDTimeLT = { default = 2.5, cast = "number", profile = "gcdtimelt", section = "fighting" },
	
	SKM_SKREADY = { default = "", cast = "string", profile = "skready", section = "fighting" },
	SKM_SKOFFCD = { default = "", cast = "string", profile = "skoffcd", section = "fighting" },
	SKM_SKNREADY = { default = "", cast = "string", profile = "sknready", section = "fighting" },
	SKM_SKNOFFCD = { default = "", cast = "string", profile = "sknoffcd", section = "fighting" },
	SKM_SKNCDTIMEMIN = { default = "", cast = "string", profile = "skncdtimemin", section = "fighting" },
	SKM_SKNCDTIMEMAX = { default = "", cast = "string", profile = "skncdtimemax", section = "fighting" },
	SKM_SKTYPE = { default = "Action", cast = "string", profile = "sktype", section = "fighting"},
	SKM_NCURRENTACTION = { default = "", cast = "string", profile = "ncurrentaction", section = "fighting" },
	
	SKM_CHAINSTART = { default = "0", cast = "string", profile = "chainstart", section = "fighting" },
	SKM_CHAINNAME = { default = "", cast = "string", profile = "chainname", section = "fighting" },
	SKM_CHAINEND = { default = "0", cast = "string", profile = "chainend", section = "fighting" },
	
	SKM_IgnoreMoving = { default = "0", cast = "string", profile = "ignoremoving", section = "fighting" },
	
	SKM_STMIN = { default = 0, cast = "number", profile = "stepmin", section = "crafting"},
	SKM_STMAX = { default = 0, cast = "number", profile = "stepmax", section = "crafting"},
	SKM_CPMIN = { default = 0, cast = "number", profile = "cpmin", section = "crafting"},
	SKM_CPMAX = { default = 0, cast = "number", profile = "cpmax", section = "crafting"},
	SKM_DURMIN = { default = 0, cast = "number", profile = "durabmin", section = "crafting"},
	SKM_DURMAX = { default = 0, cast = "number", profile = "durabmax", section = "crafting"},
	SKM_PROGMIN = { default = 0, cast = "number", profile = "progrmin", section = "crafting"},
	SKM_PROGMAX = { default = 0, cast = "number", profile = "progrmax", section = "crafting"},
	SKM_QUALMIN = { default = 0, cast = "number", profile = "qualitymin", section = "crafting"},
	SKM_QUALMAX = { default = 0, cast = "number", profile = "qualitymax", section = "crafting"},
	SKM_QUALMINPer = { default = 0, cast = "number", profile = "qualityminper", section = "crafting"},
	SKM_QUALMAXPer = { default = 0, cast = "number", profile = "qualitymaxper", section = "crafting"},
	SKM_CONDITION = { default = "NotUsed", cast = "string", profile = "condition", section = "crafting"},
	SKM_CPBuff = { default = "", cast = "string", profile = "cpbuff", section = "crafting"},
	SKM_CPNBuff = { default = "", cast = "string", profile = "cpnbuff", section = "crafting"},
	SKM_IQSTACK = { default = 0, cast = "number", profile = "iqstack", section = "crafting"},
	SKM_TOTMIN = { default = 0, cast = "number", profile = "totmin", section = "crafting"},
	SKM_TOTMAX = { default = 0, cast = "number", profile = "totmax", section = "crafting"},
	SKM_HTSUCCEED = { default = 0, cast = "number", profile = "htsucceed", section = "crafting"},
	SKM_SHSTACKMIN = { default = 0, cast = "number", profile = "shstackmin", section = "crafting"},
	SKM_MANIPMAX = { default = 0, cast = "number", profile = "manipmax", section = "crafting"},
	
	SKM_GPMIN = { default = 0, cast = "number", profile = "gpmin", section = "gathering"},
	SKM_GPMAX = { default = 0, cast = "number", profile = "gpmax", section = "gathering"},
	SKM_GAttemptsMin = { default = 0, cast = "number", profile = "gatherattempts", section = "gathering"},
	SKM_GAttemptsMax = { default = 0, cast = "number", profile = "gatherattemptsmax", section = "gathering"},
	SKM_ITEM = { default = "", cast = "string", profile = "hasitem", section = "gathering"},
	SKM_UNSP = { default = "0", cast = "string", profile = "isunspoiled", section = "gathering"},
	SKM_GSecsPassed = { default = 0, cast = "number", profile = "gsecspassed", section = "gathering"},
	SKM_ItemChanceMax = { default = 0, cast = "number", profile = "itemchancemax", section = "gathering"},
	SKM_ItemHQChanceMin = { default = 0, cast = "number", profile = "itemhqchancemin", section = "gathering"},
	SKM_GPBuff = { default = "", cast = "string", profile = "gpbuff", section = "gathering"},
	SKM_GPNBuff = { default = "", cast = "string", profile = "gpnbuff", section = "gathering"},
}

function SkillMgr.ModuleInit() 	
    Settings.FFXIVMINION.gSMactive = Settings.FFXIVMINION.gSMactive or "1"
    Settings.FFXIVMINION.gSMlastprofile = Settings.FFXIVMINION.gSMlastprofile or "None"
	Settings.FFXIVMINION.SMDefaultProfiles = Settings.FFXIVMINION.SMDefaultProfiles or {}	
	Settings.FFXIVMINION.gSkillManagerQueueing = Settings.FFXIVMINION.gSkillManagerQueueing or "0"
	
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.GLADIATOR] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.GLADIATOR] = "Gladiator"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.PUGILIST] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.PUGILIST] = "Monk"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.MARAUDER] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.MARAUDER] = "Marauder"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.LANCER] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.LANCER] = "Lancer"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ARCHER] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ARCHER] = "Archer"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.CONJURER] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.CONJURER] = "Conjurer"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.THAUMATURGE] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.THAUMATURGE] = "Black_Mage"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.CULINARIAN] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.CULINARIAN] = "Culinarian"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.PALADIN] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.PALADIN] = "Paladin"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.MONK] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.MONK] = "Monk"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.WARRIOR] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.WARRIOR] = "Warrior"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.DRAGOON] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.DRAGOON] = "Dragoon"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.BARD] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.BARD] = "Bard"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.WHITEMAGE] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.WHITEMAGE] = "White_Mage"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.BLACKMAGE] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.BLACKMAGE] = "Black_Mage"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ARCANIST] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ARCANIST] = "Arcanist"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.SUMMONER] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.SUMMONER] = "Summoner"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.SCHOLAR] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.SCHOLAR] = "Scholar"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ROGUE] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ROGUE] = "Rogue"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.NINJA] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.NINJA] = "Ninja"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.DARKKNIGHT] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.DARKKNIGHT] = "Dark Knight"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.MACHINIST] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.MACHINIST] = "Machinist"
	end
	if (Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ASTROLOGIAN] == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles[FFXIV.JOBS.ASTROLOGIAN] = "Astrologian"
	end
		
    -- Skillbook
    GUI_NewWindow(SkillMgr.skillbook.name, SkillMgr.skillbook.x, SkillMgr.skillbook.y, SkillMgr.skillbook.w, SkillMgr.skillbook.h)
    GUI_NewButton(SkillMgr.skillbook.name,GetString("skillbookrefresh"),"SMRefreshSkillbookEvent")
    GUI_UnFoldGroup(SkillMgr.skillbook.name,"AvailableSkills")
    GUI_SizeWindow(SkillMgr.skillbook.name,SkillMgr.skillbook.w,SkillMgr.skillbook.h)
    GUI_WindowVisible(SkillMgr.skillbook.name,false)	
    
    -- SelectedSkills/Main Window
    GUI_NewWindow(SkillMgr.mainwindow.name, SkillMgr.skillbook.x+SkillMgr.skillbook.w,SkillMgr.mainwindow.y,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
    GUI_NewCheckbox(SkillMgr.mainwindow.name,GetString("activated"),"gSMactive",GetString("generalSettings"))
    GUI_NewComboBox(SkillMgr.mainwindow.name,GetString("profile"),"gSMprofile",GetString("generalSettings"),"")
	GUI_NewCheckbox(SkillMgr.mainwindow.name,"Queueing Allowed","gSkillManagerQueueing",GetString("generalSettings"))
	GUI_NewCheckbox(SkillMgr.mainwindow.name,GetString("debugging"),"gSkillManagerDebug",GetString("generalSettings"))
	GUI_NewField(SkillMgr.mainwindow.name,GetString("debugItems"),"gSkillManagerDebugPriorities",GetString("generalSettings"))
	
    GUI_NewButton(SkillMgr.mainwindow.name,GetString("saveProfile"),"SMSaveEvent")
    RegisterEventHandler("SMSaveEvent",SkillMgr.SaveProfile)
	GUI_NewButton(SkillMgr.mainwindow.name,GetString("clearProfile"),"SMClearEvent")
    RegisterEventHandler("SMClearEvent",SkillMgr.ClearProfilePrompt)
    GUI_NewField(SkillMgr.mainwindow.name,GetString("newProfileName"),"gSMnewname",GetString("skillEditor"))
    GUI_NewButton(SkillMgr.mainwindow.name,GetString("newProfile"),"newSMProfileEvent",GetString("skillEditor"))
    RegisterEventHandler("newSMProfileEvent",SkillMgr.NewProfile)
    GUI_UnFoldGroup(SkillMgr.mainwindow.name,GetString("generalSettings"))
    GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    GUI_WindowVisible(SkillMgr.mainwindow.name,false)	

	GUI_NewWindow(SkillMgr.confirmwindow.name, SkillMgr.confirmwindow.x, SkillMgr.confirmwindow.y, SkillMgr.confirmwindow.w, SkillMgr.confirmwindow.h)
	GUI_NewButton(SkillMgr.confirmwindow.name,GetString("yes"),"SKMClearProfileYes")
	GUI_NewButton(SkillMgr.confirmwindow.name,GetString("no"),"SKMClearProfileNo")
	GUI_NewButton(SkillMgr.confirmwindow.name,GetString("no"),"SKMClearProfileNo")
	GUI_NewButton(SkillMgr.confirmwindow.name,GetString("no"),"SKMClearProfileNo")
	GUI_WindowVisible(SkillMgr.confirmwindow.name,false)	
                        
    gSMactive = "1"
    gSMnewname = ""
    
    -- EDITOR WINDOW
    GUI_NewWindow(SkillMgr.editwindow.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow.w, SkillMgr.editwindow.h,"",true)		
    GUI_NewField(SkillMgr.editwindow.name,GetString("maMarkerName"),"SKM_NAME",GetString("skillDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("alias"),"SKM_ALIAS",GetString("skillDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmTYPE"),"SKM_TYPE",GetString("skillDetails"))
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmSTYPE"),"SKM_STYPE",GetString("skillDetails"),"Action,Pet")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmCombat"),"SKM_Combat",GetString("skillDetails"),"In Combat,Out of Combat,Any")
	GUI_NewField(SkillMgr.editwindow.name,GetString("maMarkerID"),"SKM_ID",GetString("skillDetails"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("enabled"),"SKM_ON",GetString("skillDetails"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("skmCHARGE"),"SKM_CHARGE",GetString("basicDetails"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("appliesBuff"),"SKM_DOBUFF",GetString("basicDetails"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("removesBuff"),"SKM_REMOVESBUFF",GetString("basicDetails"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmLevelMax"),"SKM_LevelMax",GetString("basicDetails"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmLevelMin"),"SKM_LevelMin",GetString("basicDetails"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("minRange"),"SKM_MinR",GetString("basicDetails"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("maxRange"),"SKM_MaxR",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("prevComboSkill"),"SKM_PCSkillID",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("prevComboSkillNot"),"SKM_NPCSkillID",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,"Previous GCD Skill","SKM_PGSkillID",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,"Previous GCD Skill NOT","SKM_NPGSkillID",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("prevSkillID"),"SKM_PSkillID",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("prevSkillIDNot"),"SKM_NPSkillID",GetString("basicDetails"))
	--GUI_NewField(SkillMgr.editwindow.name,GetString("skmNSkillID"),"SKM_NSkillID",GetString("basicDetails"))
	--GUI_NewField(SkillMgr.editwindow.name,GetString("nextSkillPrio"),"SKM_NSkillPrio",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("currentActionNot"),"SKM_NCURRENTACTION",GetString("basicDetails"))
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("filter1"),"SKM_FilterOne",GetString("basicDetails"), "Ignore,Off,On")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("filter2"),"SKM_FilterTwo",GetString("basicDetails"), "Ignore,Off,On")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("filter3"),"SKM_FilterThree",GetString("basicDetails"), "Ignore,Off,On")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("filter4"),"SKM_FilterFour",GetString("basicDetails"), "Ignore,Off,On")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("filter5"),"SKM_FilterFive",GetString("basicDetails"), "Ignore,Off,On")
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("onlySolo"),"SKM_OnlySolo",GetString("basicDetails"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("onlyParty"),"SKM_OnlyParty",GetString("basicDetails"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("secsSinceLastCast"),"SKM_SecsPassed",GetString("basicDetails"))
	
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("chainStart"),"SKM_CHAINSTART",GetString("chain"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("name"),"SKM_CHAINNAME",GetString("chain"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("chainEnd"),"SKM_CHAINEND",GetString("chain"))
	
	GUI_NewField(SkillMgr.editwindow.name,GetString("isReady"),"SKM_SKREADY",GetString("skillChecks"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("cdIsReady"),"SKM_SKOFFCD",GetString("skillChecks"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("isNotReady"),"SKM_SKNREADY",GetString("skillChecks"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("cdNotReady"),"SKM_SKNOFFCD",GetString("skillChecks"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("cdTimeGT"),"SKM_SKNCDTIMEMIN",GetString("skillChecks"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("cdTimeLT"),"SKM_SKNCDTIMEMAX",GetString("skillChecks"))
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmSTYPE"),"SKM_SKTYPE",GetString("skillChecks"),"Action,Pet")
	
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("playerHPGT"),"SKM_PHPL",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("playerHPLT"),"SKM_PHPB",GetString("playerHPMPTP"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("underAttack"),"SKM_PUnderAttack",GetString("playerHPMPTP"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("underAttackMelee"),"SKM_PUnderAttackMelee",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("playerPowerGT"),"SKM_PPowL",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("playerPowerLT"),"SKM_PPowB",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPMPPL"),"SKM_PMPPL",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPMPPB"),"SKM_PMPPB",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTPL"),"SKM_PTPL",GetString("playerHPMPTP"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTPB"),"SKM_PTPB",GetString("playerHPMPTP"))
	--GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("skmMPLock"),"SKM_MPLock",GetString("playerHPMPTP"))
	--GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("skmMPLocked"),"SKM_MPLocked",GetString("playerHPMPTP"))
	--GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmMPLockPer"),"SKM_MPLockPer",GetString("playerHPMPTP"))
	
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTCount"),"SKM_PTCount",GetString("party"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTHPL"),"SKM_PTHPL",GetString("party"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTHPB"),"SKM_PTHPB",GetString("party"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTMPL"),"SKM_PTMPL",GetString("party"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTMPB"),"SKM_PTMPB",GetString("party"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTTPL"),"SKM_PTTPL",GetString("party"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmPTTPB"),"SKM_PTTPB",GetString("party"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmHasBuffs"),"SKM_PTBuff",GetString("party"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,"Known Debuffs","SKM_PTKBuff",GetString("party"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmMissBuffs"),"SKM_PTNBuff",GetString("party"))
	
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmTRG"),"SKM_TRG",GetString("target"),"Target,Ground Target,Player,SMN DoT,SMN Bane,Cast Target,Party,PartyS,Low TP,Low MP,Pet,Ally,Tank,Tankable Target,Tanked Target,Heal Priority,Dead Ally,Dead Party")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmTRGTYPE"),"SKM_TRGTYPE",GetString("target"),"Any,Tank,DPS,Caster,Healer")
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("skmNPC"),"SKM_NPC",GetString("target"))
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmPTRG"),"SKM_PTRG",GetString("target"),"Any,Enemy,Player")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmPGTRG"),"SKM_PGTRG",GetString("target"),"Direct,Behind")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmPPos"),"SKM_PPos",GetString("target"),"None,Front,Flanking,Behind")
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("targetHPGT"),"SKM_THPL",GetString("target"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("targetHPLT"),"SKM_THPB",GetString("target"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTHPCL"),"SKM_THPCL",GetString("target"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTHPCB"),"SKM_THPCB",GetString("target"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("hpAdvantage"),"SKM_THPADV",GetString("target"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("targetTPLE"),"SKM_TTPL",GetString("target"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("targetMPLE"),"SKM_TMPL",GetString("target"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmTCONTIDS"),"SKM_TCONTIDS",GetString("target"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmTNCONTIDS"),"SKM_TNCONTIDS",GetString("target"))
	
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmTCASTID"),"SKM_TCASTID",GetString("casting"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("skmTCASTTM"),"SKM_TCASTTM",GetString("casting"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmTCASTTIME"),"SKM_TCASTTIME",GetString("casting"))
	
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmHPRIOHP"),"SKM_HPRIOHP",GetString("healPriority"))
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmHPRIO1"),"SKM_HPRIO1",GetString("healPriority"),"Self,Tank,Party,Any,None")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmHPRIO2"),"SKM_HPRIO2",GetString("healPriority"),"Self,Tank,Party,Any,None")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmHPRIO3"),"SKM_HPRIO3",GetString("healPriority"),"Self,Tank,Party,Any,None")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmHPRIO4"),"SKM_HPRIO4",GetString("healPriority"),"Self,Tank,Party,Any,None")
	
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("enmityAOE"),"SKM_EnmityAOE",GetString("aoe"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("frontalCone"),"SKM_FrontalConeAOE",GetString("aoe"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,GetString("tankedTargetsOnly"),"SKM_TankedOnly",GetString("aoe"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTECount"),"SKM_TECount",GetString("aoe"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTECount2"),"SKM_TECount2",GetString("aoe"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTERange"),"SKM_TERange",GetString("aoe"))
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmTELevel"),"SKM_TELevel",GetString("aoe"),"0,2,4,6,Any")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("aoeCenter"),"SKM_TECenter",GetString("aoe"),"Auto,Self,Target")
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTACount"),"SKM_TACount",GetString("aoe"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("skmTARange"),"SKM_TARange",GetString("aoe"))
	GUI_NewNumeric(SkillMgr.editwindow.name,GetString("alliesNearHPLT"),"SKM_TAHPL",GetString("aoe"))
	
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmHasBuffs"),"SKM_PBuff",GetString("playerBuffs"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmAndBuffDura"),"SKM_PBuffDura",GetString("playerBuffs"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmMissBuffs"),"SKM_PNBuff",GetString("playerBuffs"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmOrBuffDura"),"SKM_PNBuffDura",GetString("playerBuffs"))
	
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("skmTBuffOwner"),"SKM_TBuffOwner",GetString("targetBuffs"), "Player,Any")
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmHasBuffs"),"SKM_TBuff",GetString("targetBuffs"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmAndBuffDura"),"SKM_TBuffDura",GetString("targetBuffs"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmMissBuffs"),"SKM_TNBuff",GetString("targetBuffs"))
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmOrBuffDura"),"SKM_TNBuffDura",GetString("targetBuffs"))
	
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmHasBuffs"),"SKM_PetBuff","Pet Buffs")
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmAndBuffDura"),"SKM_PetBuffDura","Pet Buffs")
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmMissBuffs"),"SKM_PetNBuff","Pet Buffs")
	GUI_NewField(SkillMgr.editwindow.name,GetString("skmOrBuffDura"),"SKM_PetNBuffDura","Pet Buffs")
	
	--GUI_NewComboBox(SkillMgr.editwindow.name,GetString("comboSkill"),"SKM_ComboSkill",GetString("advancedSettings"),"Auto,True,False")
	GUI_NewComboBox(SkillMgr.editwindow.name,GetString("offGCDSkill"),"SKM_OffGCD",GetString("advancedSettings"),"Auto,True,False")
	GUI_NewField(SkillMgr.editwindow.name,"Off GCD Time >=","SKM_OffGCDTime",GetString("advancedSettings"))
	GUI_NewField(SkillMgr.editwindow.name,"Off GCD Time <=","SKM_OffGCDTimeLT",GetString("advancedSettings"))
	GUI_NewCheckbox(SkillMgr.editwindow.name,"Ignore Moving","SKM_IgnoreMoving",GetString("advancedSettings"))
	
	
    GUI_UnFoldGroup(SkillMgr.editwindow.name,GetString("skillDetails"))
	
    GUI_NewButton(SkillMgr.editwindow.name,"DELETE","SMEDeleteEvent")
    GUI_NewButton(SkillMgr.editwindow.name,"DOWN","SMESkillDOWNEvent")	
    GUI_NewButton(SkillMgr.editwindow.name,"UP","SMESkillUPEvent")
	GUI_NewButton(SkillMgr.editwindow.name,"PASTE","SKMPasteSkill")
	GUI_NewButton(SkillMgr.editwindow.name,"COPY","SKMCopySkill")
    GUI_SizeWindow(SkillMgr.editwindow.name,SkillMgr.editwindow.w,SkillMgr.editwindow.h)
    GUI_WindowVisible(SkillMgr.editwindow.name,false)
    
    -- Crafting EDITOR WINDOW
    GUI_NewWindow(SkillMgr.editwindow_crafting.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow_crafting.w, SkillMgr.editwindow_crafting.h,"",true)		
    GUI_NewField(SkillMgr.editwindow_crafting.name,GetString("maMarkerName"),"SKM_NAME",GetString("skillDetails"))
	GUI_NewField(SkillMgr.editwindow_crafting.name,GetString("skmTYPE"),"SKM_TYPE",GetString("skillDetails"))
    GUI_NewField(SkillMgr.editwindow_crafting.name,GetString("maMarkerID"),"SKM_ID",GetString("skillDetails"))
    GUI_NewCheckbox(SkillMgr.editwindow_crafting.name,GetString("enabled"),"SKM_ON",GetString("skillDetails"))	
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("stepmin"),"SKM_STMIN",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("stepmax"),"SKM_STMAX",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("cpmin"),"SKM_CPMIN",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("cpmax"),"SKM_CPMAX",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("durabmin"),"SKM_DURMIN",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("durabmax"),"SKM_DURMAX",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("progrmin"),"SKM_PROGMIN",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("progrmax"),"SKM_PROGMAX",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("qualitymin"),"SKM_QUALMIN",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("qualitymax"),"SKM_QUALMAX",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("qualityminper"),"SKM_QUALMINPer",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("qualitymaxper"),"SKM_QUALMAXPer",GetString("skillDetails"))   
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("totMin"),"SKM_TOTMIN",GetString("skillDetails"));
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("totMax"),"SKM_TOTMAX",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("htSucceedMax"),"SKM_HTSUCCEED",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("shStackMin"),"SKM_SHSTACKMIN",GetString("skillDetails"));
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("manipMax"),"SKM_MANIPMAX",GetString("skillDetails"));
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,GetString("iqstack"),"SKM_IQSTACK",GetString("skillDetails"));
	
    GUI_NewComboBox(SkillMgr.editwindow_crafting.name,GetString("condition"),"SKM_CONDITION",GetString("skillDetails"),GetString("notused")..","..GetString("excellent")..","..GetString("good")..","..GetString("normal")..","..GetString("poor"))
	GUI_NewField(SkillMgr.editwindow_crafting.name,GetString("skmHasBuffs"),"SKM_CPBuff",GetString("skillDetails"));
    GUI_NewField(SkillMgr.editwindow_crafting.name,GetString("skmMissBuffs"),"SKM_CPNBuff",GetString("skillDetails"));
	
	
	GUI_UnFoldGroup(SkillMgr.editwindow_crafting.name,GetString("skillDetails"))
    GUI_NewButton(SkillMgr.editwindow_crafting.name,"DELETE","SMEDeleteEvent")	
    GUI_NewButton(SkillMgr.editwindow_crafting.name,"DOWN","SMESkillDOWNEvent")	
    GUI_NewButton(SkillMgr.editwindow_crafting.name,"UP","SMESkillUPEvent")
	GUI_NewButton(SkillMgr.editwindow_crafting.name,"PASTE","SKMPasteSkill")
	GUI_NewButton(SkillMgr.editwindow_crafting.name,"COPY","SKMCopySkill")
    GUI_SizeWindow(SkillMgr.editwindow_crafting.name,SkillMgr.editwindow_crafting.w,SkillMgr.editwindow_crafting.h)
    GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)
    
    -- Gathering EDITOR WINDOW
    GUI_NewWindow(SkillMgr.editwindow_gathering.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow_gathering.w, SkillMgr.editwindow_gathering.h,"",true)		
    GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("maMarkerName"),"SKM_NAME",GetString("skillDetails"))
	GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("skmTYPE"),"SKM_TYPE",GetString("skillDetails"))
    GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("maMarkerID"),"SKM_ID",GetString("skillDetails"))
    GUI_NewCheckbox(SkillMgr.editwindow_gathering.name,GetString("enabled"),"SKM_ON",GetString("skillDetails"))	
    GUI_NewNumeric(SkillMgr.editwindow_gathering.name,GetString("gpmin"),"SKM_GPMIN",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_gathering.name,GetString("gpmax"),"SKM_GPMAX",GetString("skillDetails"));
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,"Chance <=","SKM_ItemChanceMax",GetString("skillDetails"));
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,"HQ Chance >=","SKM_ItemHQChanceMin",GetString("skillDetails"));
    GUI_NewNumeric(SkillMgr.editwindow_gathering.name,GetString("gatherAttemptsMin"),"SKM_GAttemptsMin",GetString("skillDetails"));
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,GetString("gatherAttemptsMax"),"SKM_GAttemptsMax",GetString("skillDetails"));
    GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("nodeHas"),"SKM_ITEM",GetString("skillDetails"));
	GUI_NewCheckbox(SkillMgr.editwindow_gathering.name,GetString("skmUnspoiled"),"SKM_UNSP",GetString("skillDetails"))
	GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("secsSinceLastCast"),"SKM_GSecsPassed", GetString("skillDetails"))
	GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("skmHasBuffs"),"SKM_GPBuff",GetString("skillDetails"));
	GUI_NewField(SkillMgr.editwindow_gathering.name,GetString("skmMissBuffs"),"SKM_GPNBuff",GetString("skillDetails"));

    GUI_UnFoldGroup(SkillMgr.editwindow_gathering.name,GetString("skillDetails"))
    GUI_NewButton(SkillMgr.editwindow_gathering.name,"DELETE","SMEDeleteEvent")
    GUI_NewButton(SkillMgr.editwindow_gathering.name,"DOWN","SMESkillDOWNEvent")		
    GUI_NewButton(SkillMgr.editwindow_gathering.name,"UP","SMESkillUPEvent")
	GUI_NewButton(SkillMgr.editwindow_gathering.name,"PASTE","SKMPasteSkill")
	GUI_NewButton(SkillMgr.editwindow_gathering.name,"COPY","SKMCopySkill")
    GUI_SizeWindow(SkillMgr.editwindow_gathering.name,SkillMgr.editwindow_gathering.w,SkillMgr.editwindow_gathering.h)
    GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)

    SkillMgr.SkillBook = {}
	SkillMgr.UpdateProfiles()
    SkillMgr.UpdateCurrentProfileData()
    GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
	
	SkillMgr.AddDefaultConditions()
	
	gSkillManagerQueueing = Settings.FFXIVMINION.gSkillManagerQueueing
end

function SkillMgr.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		
        if (k == "gSMactive" or
			k == "gSkillManagerQueueing") 
		then			
            SafeSetVar(tostring(k),v)	
		elseif ( k == "gSMprofile" ) then
            gSMactive = "1"					
            GUI_WindowVisible(SkillMgr.editwindow.name,false)
            GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)			
            GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
            SkillMgr.UpdateCurrentProfileData()
			SafeSetVar("gSMlastprofile",v)
			SkillMgr.SetDefaultProfile()
		end
		
		if (SkillMgr.Variables[tostring(k)] ~= nil and tonumber(SKM_Prio) ~= nil and SKM_Prio > 0) then	
			if (v == "?") then
				d("Question mark was typed.")
			end
			if (v == nil) then
				SkillMgr.SkillProfile[SKM_Prio][SkillMgr.Variables[tostring(k)].profile] = SkillMgr.Variables[tostring(k)].default
			elseif (SkillMgr.Variables[k].cast == "string") then
				SkillMgr.SkillProfile[SKM_Prio][SkillMgr.Variables[tostring(k)].profile] = v
			elseif (SkillMgr.Variables[k].cast == "number") then
				SkillMgr.SkillProfile[SKM_Prio][SkillMgr.Variables[tostring(k)].profile] = tonumber(v)
			end
		end
    end
end

function SkillMgr.OnUpdate( event, tickcount )
	if ((tickcount - SkillMgr.lastTick) > 150) then
		SkillMgr.lastTick = tickcount
		
		local job = Player.job
		if (Player.castinginfo.channelingid ~= 0) then
			local channelingskill = Player.castinginfo.channelingid
			SkillMgr.UpdateLastCast(channelingskill)
		end
		
		if (Player.castinginfo.castingid ~= 0) then
			local castingskill = Player.castinginfo.castingid
			if ( job >= 8 and job <=15 ) then
				local action = ActionList:Get(castingskill,9)
				if (action) then
					SkillMgr.prevSkillID = castingskill
					SkillMgr.UpdateLastCast(castingskill)
				end
			else
				if (SkillMgr.prevSkillID ~= castingskill) then
					local action = ActionList:Get(castingskill,1)
					if (action) then
						--d("Setting previous skill ID to :"..tostring(castingskill).."["..action.name.."]")
						SkillMgr.prevSkillID = castingskill
						SkillMgr.prevSkillTimestamp = Now()
						if (action.recasttime == 2.5) then
							SkillMgr.prevGCDSkillID = castingskill
						end
						SkillMgr.UpdateLastCast(castingskill)
						SkillMgr.failTimer = Now() + 6000
					end
				end
				if (SkillMgr.queuedPrio ~= 0) then
					local action = ActionList:Get(castingskill,1)
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
end

--This is the only function that should actually read from the file.
function SkillMgr.ReadFile(strFile)
	assert(type(strFile) == "string" and strFile ~= "", "[SkillMgr.ReadFile]: File target is not valid")
	local filename = SkillMgr.profilepath..strFile..".lua"
	
	--Attempt to read old files and convert them.
	local profile = fileread(filename)
	if (profile) then
		local version = nil
		for i,line in pairsByKeys(profile) do
			local _, key, id, value = string.match(line, "(%w+)_(%w+)_(%d+)=(.*)")
			if ( tostring(key) == "SMVersion" and tostring(id) == "1") then
				version = 1
			end
			if (version == 1) then
				break
			end
		end
		if (version == 1) then
			local newskill = {}
			local sortedSkillList = {}
			for i,line in pairsByKeys(profile) do
				local _, key, value = string.match(line, "(%w+)_(%w+)=(.*)")
				if ( key and value ) then
					value = string.gsub(value, "\r", "")					
					if ( key == "END" ) then
						local job = Player.job
						if (job >= 8 and job <= 15) then
							for k,v in pairs(SkillMgr.Variables) do
								if (v.section == "crafting") then
									newskill[v.profile] = newskill[v.profile] or v.default
								end
							end
						elseif (job >=16 and job <=17) then
							for k,v in pairs(SkillMgr.Variables) do
								if (v.section == "gathering") then
									newskill[v.profile] = newskill[v.profile] or v.default
								end
							end
						else
							for k,v in pairs(SkillMgr.Variables) do
								if (v.section == "fighting") then
									newskill[v.profile] = newskill[v.profile] or v.default
								end
							end
						end
						
						-- try to update the names 
						local found = false
						for i, actiontype in pairsByKeys(SkillMgr.ActionTypes) do
							local actionlist = ActionList("type="..tostring(actiontype))
							for k, action in pairs(actionlist) do
								if (action.id == newskill.id and action.name and action.name ~= "") then
									newskill.name = action.name
									found = true
									break
								end
							end
							if (found) then
								break
							end
						end
						
						sortedSkillList = TableInsertSort(sortedSkillList,tonumber(newskill.prio),newskill)
						newskill = {}
					elseif (SkillMgr.Variables["SKM_"..key] ~= nil) then
						local t = SkillMgr.Variables["SKM_"..key]
						if (t ~= nil) then
							if (t.cast == "number") then
								newskill[t.profile] = tonumber(value)
							elseif (t.cast == "string") then
								if (key == "TRG" and value == "Enemy") then
									newskill[t.profile] = GetString("target")
								else
									newskill[t.profile] = tostring(value)
								end
							end
						end
					end
				end
			end
			if ( TableSize(sortedSkillList) > 0 ) then
				local reorder = 1
				for k,v in pairsByKeys(sortedSkillList) do
					v.prio = reorder
					SkillMgr.SkillProfile[reorder] = v
					reorder = reorder + 1
				end
			end
			--Overwrite the old file with the new file type.
			SkillMgr.WriteToFile(strFile)
		end
	end	
	
	--Load the file, which should only be the new type.
	local profile, e = persistence.load(filename)
	if (ValidTable(profile)) then
		SkillMgr.SkillProfile = profile.skills
	end
	SkillMgr.ResetSkillTracking()
	SkillMgr.CheckProfileValidity()
end

--All writes to the profiles should come through this function.
function SkillMgr.WriteToFile(strFile)
	assert(strFile and type(strFile) == "string" and strFile ~= "", "[SkillMgr.WriteToFile]: File target is not valid.")
	assert(string.find(strFile,"\\") == nil, "[SkillMgr.WriteToFile]: File contains illegal characters.")
	
	local filename = SkillMgr.profilepath ..strFile..".lua"
	
	local info = {}
	info.version = 2
	SkillMgr.ResetSkillTracking()
	info.skills = SkillMgr.SkillProfile or {}	
	persistence.store(filename,info)
end

function SkillMgr.SetGUIVar(strName, value)
	if (SkillMgr.Variables[strName] ~= nil and SKM_Prio ~= nil and SKM_Prio > 0) then	
		skillVar = SkillMgr.Variables[strName]
		if (value == nil) then
			SkillMgr.SkillProfile[SKM_Prio][skillVar.profile] = skillVar.default
		elseif (skillVar.cast == "string") then
			SkillMgr.SkillProfile[SKM_Prio][skillVar.profile] = value
		elseif (skillVar.cast == "number") then
			SkillMgr.SkillProfile[SKM_Prio][skillVar.profile] = tonumber(value)
		end
	end
end

function SkillMgr.CheckProfileValidity()
	local profile = SkillMgr.SkillProfile
	
	local job = Player.job
	local requiredUpdate = false
	if (ValidTable(profile)) then
		for prio,skill in pairsByKeys(profile) do
			local skID = tonumber(skill.id)
			local skType = tonumber(skill.type)
			local realskilldata = ActionList:Get(skID,skType)
			
			if (tonumber(skill.prio) ~= tonumber(prio)) then
				skill.prio = tonumber(prio)
				requiredUpdate = true
			end
			
			--First pass, make sure the profile has all the required conditionals.
			if (job >= 8 and job <= 15) then
				for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "crafting") then
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
			elseif (job >=16 and job <=17) then
				for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "gathering") then
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
					if (v.section == "fighting") then
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
						if (v.cast == "number") then
							skill[v.profile] = tonumber(skill[v.profile])
						elseif (v.cast == "string") then
							skill[v.profile] = tonumber(skill[v.profile])
						else
							
						end
					end
				end
			end
		end
	end
	
	if (not deepcompare(SkillMgr.SkillProfile,profile,true)) then
		SkillMgr.SkillProfile = profile
	end
	
	if (requiredUpdate) then
		SkillMgr.SaveProfile()
	end
end

function SkillMgr.UseProfile(strName)
	gSMprofile = strName
    gSMactive = "1"					
	GUI_WindowVisible(SkillMgr.editwindow.name,false)
	GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)			
	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
	SkillMgr.UpdateCurrentProfileData()
	Settings.FFXIVMINION.gSMlastprofile = strName
end

function SkillMgr.ButtonHandler(event, Button)
    gSMRecactive = "0"
	if (event == "GUI.Item" and (string.find(Button,"SKM") ~= nil or string.find(Button,"SM") ~= nil )) then
	
		if (string.find(Button,"SMDeleteEvent") ~= nil) then
			-- Delete the currently selected Profile - file from the HDD
			if (gSMprofile ~= nil and gSMprofile ~= "None" and gSMprofile ~= "") then
				d("Deleting current Profile: "..gSMprofile)
				os.remove(SkillMgr.profilepath ..gSMprofile..".lua")	
				SkillMgr.UpdateProfiles()	
			end
		end
		
		if (string.find(Button,"SMRefreshSkillbookEvent") ~= nil) then
			SkillMgr.SkillBook = {}
			GUI_DeleteGroup(SkillMgr.skillbook.name,"AvailableSkills")
			GUI_DeleteGroup(SkillMgr.skillbook.name,"MiscSkills")	
			SkillMgr.RefreshSkillBook()		
		end
        
		if (string.find(Button,"SMEDeleteEvent") ~= nil) then
			if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
				GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
				SkillMgr.SkillProfile = TableRemoveSort(SkillMgr.SkillProfile,tonumber(SKM_Prio))

				SkillMgr.RefreshSkillList()	
				GUI_WindowVisible(SkillMgr.editwindow.name,false)
				GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)	
				GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)
			end
		end

		if (string.find(Button,"SMESkillUPEvent") ~= nil) then
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
	
		if (string.find(Button,"SMESkillDOWNEvent") ~= nil) then
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
	
		if (string.find(Button,"SKMEditSkill") ~= nil) then
			local key = Button:gsub("SKMEditSkill", "")
			SkillMgr.EditSkill(key)
		end
		if (string.find(Button,"SKMClearProfile") ~= nil) then
			local key = Button:gsub("SKMClearProfile", "")
			SkillMgr.ClearProfile(key)
		end
		if (string.find(Button,"SKMAddSkill") ~= nil) then
			local key = Button:gsub("SKMAddSkill", "")
			SkillMgr.AddSkillToProfile(1,key)
		end
		if (string.find(Button,"SKMAddPetSkill") ~= nil) then
			local key = Button:gsub("SKMAddPetSkill", "")
			SkillMgr.AddSkillToProfile(11,key)
		end
		if (string.find(Button,"SKMAddCraftSkill") ~= nil) then
			local key = Button:gsub("SKMAddCraftSkill", "")
			SkillMgr.AddSkillToProfile(9,key)
		end
		if (string.find(Button,"SKMCopySkill") ~= nil) then
			SkillMgr.CopySkill()
		end
		if (string.find(Button,"SKMPasteSkill") ~= nil) then
			SkillMgr.PasteSkill()
		end
	end
end

function SkillMgr.NewProfile()
    if ( gSMnewname and gSMnewname ~= "" ) then
		gSMprofile_listitems = gSMprofile_listitems..","..gSMnewname
        gSMprofile = gSMnewname
        gSMnewname = ""
		
		GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
		SkillMgr.SkillProfile = {}
		SkillMgr.WriteToFile(gSMprofile)
	else
		d("New profile name is invalid, couldn't create new profile.")
    end
end

function SkillMgr.ClearProfilePrompt()
	local wnd = GUI_GetWindowInfo(SkillMgr.mainwindow.name)
	GUI_MoveWindow(SkillMgr.confirmwindow.name, wnd.x,wnd.y+wnd.height) 
	GUI_SizeWindow(SkillMgr.confirmwindow.name,wnd.width,SkillMgr.confirmwindow.h)
	GUI_WindowVisible(SkillMgr.confirmwindow.name,true)
end

function SkillMgr.ClearProfile(arg)
	if (arg == "Yes") then
		GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
		SkillMgr.SkillProfile = {}
		SkillMgr.WriteToFile(gSMprofile)
	end
	GUI_WindowVisible(SkillMgr.confirmwindow.name,false)
end

function SkillMgr.SaveProfile()
    local filename = ""
	
    --If a new name is filled out, copy the profile rather than save it.
    if ( gSMnewname ~= "" ) then
        filename = gSMnewname
        gSMnewname = ""

		gSMprofile_listitems = gSMprofile_listitems..","..filename
		gSMprofile = filename
		Settings.FFXIVMINION.gSMlastprofile = filename
		
		SkillMgr.WriteToFile(filename)
    elseif (gSMprofile ~= nil and gSMprofile ~= "None" and gSMprofile ~= "") then
        filename = gSMprofile
        gSMnewname = ""		
		
		SkillMgr.WriteToFile(filename)
    end
end

function SkillMgr.SetDefaultProfile(strName)
	local profile = strName or gSMprofile
	Settings.FFXIVMINION.SMDefaultProfiles[Player.job] = profile
	Settings.FFXIVMINION.SMDefaultProfiles = Settings.FFXIVMINION.SMDefaultProfiles
end

function SkillMgr.UseDefaultProfile()
	local defaultTable = Settings.FFXIVMINION.SMDefaultProfiles
	local default = nil
	local profile = nil
	local profileFound = false
	
	--Try default profile first.
	if (ValidTable(defaultTable)) then
		default = defaultTable[Player.job]
		if (default) then
			if (FileExists(SkillMgr.profilepath..default..".lua")) then
				profileFound = true
			end
		end
	end
	
	if (not profileFound) then
		local starterDefault = SkillMgr.StartingProfiles[Player.job]
		if ( starterDefault ) then
			local filePath = SkillMgr.profilepath..starterDefault..".lua"
			if (FileExists(filePath)) then
				d("No default profile set, using start default ["..tostring(starterDefault).."]")
				SkillMgr.SetDefaultProfile(starterDefault)
				default = starterDefault
				profileFound = true
			end
		end
	end
	
	gSMprofile = profileFound and default or "None"
	GUI_WindowVisible(SkillMgr.editwindow.name,false)
	GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)	
	GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)		
	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
	SkillMgr.UpdateCurrentProfileData()
	
	GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
end

--Grasb all Profiles and enlist them in the dropdown field
function SkillMgr.UpdateProfiles()
    
    local profiles = "None"
    local found = "None"	
    local profilelist = dirlist(SkillMgr.profilepath,".*lua")
    if ( TableSize(profilelist) > 0) then			
        local i,profile = next ( profilelist)
        while i and profile do				
            profile = string.gsub(profile, ".lua", "")
            profiles = profiles..","..profile
            if ( Settings.FFXIVMINION.gSMlastprofile ~= nil and Settings.FFXIVMINION.gSMlastprofile == profile ) then
                found = profile
            end
            i,profile = next ( profilelist,i)
        end		
    else
        d("No Skillmanager profiles found")
    end
	
    gSMprofile_listitems = profiles
    gSMprofile = found
	
	return profiles
end

function SkillMgr.CopySkill()
	d("COPYING SKILL #:"..tostring(SKM_Prio))
	local source = SkillMgr.SkillProfile[tonumber(SKM_Prio)]
	SkillMgr.copiedSkill = {}
	local temp = {}
	for k,v in pairs(SkillMgr.Variables) do
		if (v.section ~= "main") then
			temp[k] = _G[tostring(k)]
		end
	end
	SkillMgr.copiedSkill = temp
end

function SkillMgr.PasteSkill()
	d("PASTING INTO SKILL #:"..tostring(SKM_Prio))
	local source = SkillMgr.copiedSkill
	for k,v in pairs(SkillMgr.copiedSkill) do
		_G[tostring(k)] = v
		SkillMgr.SetGUIVar(tostring(k),v)
	end
end

function SkillMgr.UpdateCurrentProfileData()
	local profile = gSMprofile
	if (profile and profile ~= "") then
		GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
		SkillMgr.SkillProfile = {}
		SkillMgr.ReadFile(profile)
		SkillMgr.RefreshSkillList()
		GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
		GUI_RefreshWindow(SkillMgr.mainwindow.name)
	end
end

--+Rebuilds the UI Entries for the SkillbookList
function SkillMgr.RefreshSkillBook()
	local job = Player.job
	
    local SkillList = ActionList("type=1,minlevel=1")
    if ( ValidTable( SkillList ) ) then
		for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
			SkillMgr.CreateNewSkillBookEntry(i)
		end
    end
	
	local SkillList = ActionList("type=1,level=0")
    if ( ValidTable( SkillList ) ) then
		for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
			if (skill.level == 0) then
				SkillMgr.CreateNewSkillBookEntry(i, 1, "MiscSkills")
			end
		end
    end
 
	--summoning pet skills
	if ( job >= 26 ) then
		SkillList = ActionList("type=11")
		if ( ValidTable( SkillList) ) then
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
		if ( ValidTable( SkillList ) ) then
			for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
				SkillMgr.CreateNewSkillBookEntry(i, 9)
			end
		end
    end

    GUI_UnFoldGroup(SkillMgr.skillbook.name,"AvailableSkills")
end


function SkillMgr.CreateNewSkillBookEntry(id, actiontype, group)
	actiontype = actiontype or 1
	local action = ActionList:Get(id,actiontype)
	if (ValidTable(action)) then
		local skName = action.name
		local skID = tostring(action.id)
			
		local handlers = {
			[1] = "SKMAddSkill",
			[9] = "SKMAddCraftSkill",
			[11] = "SKMAddPetSkill",
		}
		
		if (group) then
			GUI_NewButton(SkillMgr.skillbook.name, skName.." ["..skID.."]", handlers[actiontype]..skID, group)
		else
			GUI_NewButton(SkillMgr.skillbook.name, skName.." ["..skID.."]", handlers[actiontype]..skID, "AvailableSkills")
		end
		
		if (not ValidTable(SkillMgr.SkillBook[actiontype])) then
			SkillMgr.SkillBook[actiontype] = {}
		end
		
		local bookSection = SkillMgr.SkillBook[actiontype]
		bookSection[action.id] = {["id"] = action.id, ["name"] = action.name, ["type"] = actiontype}
		--SkillMgr.SkillBook[action.id] = {["id"] = action.id, ["name"] = action.name, ["type"] = actiontype}	
	else
		ml_error("Action ID:"..tostring(id)..", Type:"..tostring(actiontype).." is not valid and could not be retrieved.")
	end
end

-- Button Handler for Skillbook-skill-buttons
function SkillMgr.AddSkillToProfile(skilltype,skillid)
	local skilltype = tonumber(skilltype)
	local skillid = tonumber(skillid)
	
	local bookSection = SkillMgr.SkillBook[skilltype]
	if (ValidTable(bookSection)) then
		local thisAction = bookSection[skillid]
		if (thisAction) then
			SkillMgr.CreateNewSkillEntry(thisAction)
		end
	end
end


--+Rebuilds the UI Entries for the Profile-SkillList
function SkillMgr.RefreshSkillList()
	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    if ( TableSize( SkillMgr.SkillProfile ) > 0 ) then
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			local clientSkill = GetSkillByID(skill.id,skill.type)
			local skillFound = ValidTable(clientSkill)
			local skillName = (clientSkill and clientSkill.name) or skill.name
			local viewString = ""
			if (not IsNullString(skill.alias)) then
				viewString = tostring(prio)..": "..skill.alias.."["..tostring(skill.id).."]"
			else
				viewString = tostring(prio)..": "..skillName.."["..tostring(skill.id).."]"
			end
			if (not skillFound) then
				viewString = "***"..viewString.."***"
			end
			GUI_NewButton(SkillMgr.mainwindow.name, viewString, "SKMEditSkill"..tostring(prio),"ProfileSkills")
		end
		GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    end
end

function SkillMgr.ResetSkillTracking()
	local skills = SkillMgr.SkillProfile
	if (ValidTable(skills)) then
		for prio,skill in pairs(skills) do
			skill.lastcast = 0
		end
	end
end

function SkillMgr.CreateNewSkillEntry(skill)
	assert(type(skill) == "table", "CreateNewSkillEntry was called with a non-table value.")
	
	if (not skill.name or not skill.id or not skill.type) then
		return false
	end
	
	local skName = skill.name
	local skID = tonumber(skill.id)
	local skType = tonumber(skill.type) or 1
	local realskilldata = ActionList:Get(skID,skType)
	local job = Player.job
	local newskillprio = TableSize(SkillMgr.SkillProfile)+1

	SkillMgr.SkillProfile[newskillprio] = {	["id"] = skID, ["prio"] = newskillprio, ["name"] = skName, ["used"] = "1", ["alias"] = "", ["type"] = skType }
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
						SkillMgr.SkillProfile[newskillprio][v.profile] = "Pet"
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
	SkillMgr.RefreshSkillList()
end	

--+	Button Handler for ProfileList Skills
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
		SkillMgr.RefreshSkillList()
		GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
        GUI_WindowVisible(SkillMgr.skillbook.name,true)
        GUI_WindowVisible(SkillMgr.mainwindow.name,true)	
        SkillMgr.visible = true
    end
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
	
	local petstring = contentids[skillID]
	if (petstring) then
		local el = EntityList("ownerid="..tostring(Player.id)..",contentid="..petstring)
		if (ValidTable(el)) then
			local i,entity = next(el)
			if (i and entity) then
				return true
			end
		end
	end
		
    return false
end

function SkillMgr.IsReviveSkill(skillID)
    if (skillID == 173 or skillID == 125 or skillID == 3603) then
        return true
    end
    return false
end

function SkillMgr.UpdateLastCast(skillid)
	local skillid = tonumber(skillid) or 0
	
	if (ValidTable(SkillMgr.SkillProfile)) then
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			if (tonumber(skill.id) == skillid) then
				SkillMgr.SkillProfile[prio].lastcast = Now()
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
		[2868] = "Slug Shot",
		[2873] = "Clean Shot",		
		[2871] = "Grenado Shot"

	}
	
	return affectedSkills[skillid]
end

function SkillMgr.UpdateChain(prio,castedskill)
	local prio = tonumber(prio) or 0
	local castedskill = tonumber(castedskill) or 0
	
	if (prio ~= 0 and castedskill ~= 0) then
		if (ValidTable(SkillMgr.SkillProfile)) then
			local thisSkill = SkillMgr.SkillProfile[prio]
			if (ValidTable(thisSkill) and (thisSkill.id == castedskill or (IsNinjutsuSkill(thisSkill.id) and IsNinjutsuSkill(castedskill)))) then
				if (thisSkill.chainstart == "1") then
					SkillMgr.currentChain = thisSkill.chainname
					d("Starting chain ["..tostring(SkillMgr.currentChain).."]")
					return true
				elseif (thisSkill.chainend == "1") then
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

-- Goes through all spells and returns the highest HP% of all spells
function SkillMgr.GetHealSpellHPLimit()
	local highestHPLimit = 0
	if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
		for prio,skill in pairs(SkillMgr.SkillProfile) do
			if ( skill.thpb > 0 and skill.thpb > highestHPLimit ) then
				highestHPLimit = skill.thpb
			end
		end
	end
	return highestHPLimit
end

function SkillMgr.GetTankableTarget( range )
	local range = range or ml_global_information.AttackRange
	local closest = nil
	local closestRange = 100
	local targets = {}
	
	local party = EntityList("myparty,chartype=4")
	if (ValidTable(party)) then
		for i,member in pairs(party) do
			if (member.id ~= Player.id) then
				local list = EntityList("nearest,alive,attackable,targeting="..tostring(member.id)..",maxrange="..tostring(range))
				if (ValidTable(list)) then
					for k,entity in pairs(list) do
						targets[k] = entity
					end
				end
			end
		end
	end
	
	if (ValidTable(targets)) then
		for k,entity in pairs(targets) do
			if (not closest or (closest and entity.distance < closestRange)) then
				closest = entity
				closestRange = entity.distance
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
    if ( ValidTable(party) ) then
		for i,e in pairs(party) do
			if (IsTank(e.job)) then
				tanks[i] = e
			end
        end
    end
	
	if (ValidTable(tanks)) then
		for i,tank in pairs(tanks) do
			local list = EntityList("nearest,alive,attackable,targeting="..tostring(tank.id)..",maxrange="..tostring(range))
			if (ValidTable(list)) then
				for k,entity in pairs(list) do
					targets[k] = entity
				end
			end
		end
	end
	
	if (ValidTable(targets)) then
		for i,target in pairs(targets) do
			if (not closest or (closest and closest.distance < closestRange)) then
				closest = target
				closestRange = target.distance
			end
		end
		
		return closest
	end
	
	return nil
end

function SkillMgr.Cast( entity , preCombat, forceStop )
	preCombat = preCombat or false
	forceStop = forceStop or false
	
	if (not entity) then
		return false
	end
				
	--Check for current target cast preventions first.
	local cp = Settings.FFXIVMINION.cpOptions
	local target = Player:GetTarget()
	if (target) then
		for k,v in pairs(cp) do
			if ( v.castids and v.castids ~= "" ) then
				if (isCasting(target, v.castids, nil, nil )) then
					if (ActionList:IsCasting()) then
						ActionList:Cast(2,Player.id,5)
					end
					return false
				end
			elseif (v.tbuffs and v.tbuffs ~= "" ) then
				if (HasBuffs(target, v.tbuffs)) then
					return false
				end
			end
		end
	end	
	
	--This call is here to refresh the action list in case new skills are equipped.
	local al = ActionList("type=1")
	
	if (SkillMgr.SkillProfile) then
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			
			local result = SkillMgr.CanCast(prio, entity, preCombat)
			if (result ~= 0) then
				local TID = result
				
				if (skill.stype == "Pet") then	
					if (skill.trg == "Ground Target") then
						local s = ActionList:Get(skill.id,11)
						
						local entity = EntityList:Get(TID)
						if (entity) then
							local tpos = entity.pos
							if (skill.pgtrg == "Behind") then
								local eh = ConvertHeading(tpos.h)
								local mobRear = ConvertHeading((eh - (math.pi)))%(2*math.pi)
								local rangePercent = tonumber(gCombatRangePercent) * 0.01
								local dist = math.random(entity.hitradius + 5, entity.hitradius + 10)
								if (dist < 2) then
									dist = 2
								end
						
								local newpos = GetPosFromDistanceHeading(tpos, dist, mobRear)
								if (newpos) then
									tpos = newpos
								end
							end
							local attempt = 1
							while (s.isready and attempt <= 3) do
								s:Cast(tpos.x, tpos.y, tpos.z)
								s = ActionList:Get(skill.id,11)
								attempt = attempt + 1
							end	
						end
					else
						local s = ActionList:Get(skill.id,11)
						SkillMgr.DebugOutput(prio, "Grabbed pet skill:"..tostring(s.name).." to cast on target ID :"..tostring(TID))
						
						local attempt = 1
						while (s.isready and attempt <= 3) do
							SkillMgr.DebugOutput(prio, "Attempting cast for pet skill, attempt #:"..tostring(attempt))
							
							ActionList:Cast(skill.id,TID,11)
							s = ActionList:Get(skill.id,11)
							attempt = attempt + 1
						end		
						if (SkillMgr.SkillProfile[prio]) then
							SkillMgr.SkillProfile[prio].lastcast = Now()
						else
							d("An error occurred setting last cast.  Priority " .. prio .. " seems to be missing.")
						end
					end
				else
					if (skill.trg == "Ground Target") then
						local action = ActionList:Get(skill.id)
						
						local entity = EntityList:Get(TID)
						if (entity) then
							local tpos = entity.pos
							if (skill.pgtrg == "Behind") then
								local eh = ConvertHeading(tpos.h)
								local mobRear = ConvertHeading((eh - (math.pi)))%(2*math.pi)
								local rangePercent = tonumber(gCombatRangePercent) * 0.01
								local dist = (entity.hitradius * rangePercent)
								if (dist < 2) then
									dist = 2
								end
						
								local newpos = GetPosFromDistanceHeading(tpos, dist, mobRear)
								if (newpos) then
									tpos = newpos
								end
							end
							
							if (action:Cast(tpos.x, tpos.y, tpos.z)) then
								SkillMgr.latencyTimer = Now()
								
								local castingskill = Player.castinginfo.castingid
								if (castingskill == action.id or (IsNinjutsuSkill(castingskill) and IsNinjutsuSkill(action.id))) then
									SkillMgr.prevSkillID = castingskill
									SkillMgr.prevSkillTimestamp = Now()
									if (action.recasttime == 2.5) then
										SkillMgr.prevGCDSkillID = castingskill
									end
									SkillMgr.UpdateLastCast(castingskill)
									if (SkillMgr.UpdateChain(prio,castingskill)) then
										SkillMgr.queuedPrio = 0
									end
									SkillMgr.failTimer = Now() + 6000
								else
									if (skill.chainstart == "1" or skill.chainend == "1") then
										SkillMgr.queuedPrio = prio
									end
								end
								
								return true
							end
						end
					else
						local action = ActionList:Get(skill.id,1,TID)
						if (ValidTable(action)) then
							if (gSkillManagerQueueing == "1") then
								SkillMgr.DebugOutput(prio, "Attempting to cast skill:"..tostring(action.name))
							end
							if (action:Cast(TID)) then
								SkillMgr.latencyTimer = Now()
								
								local castingskill = Player.castinginfo.castingid
								if (castingskill == action.id or (IsNinjutsuSkill(castingskill) and IsNinjutsuSkill(action.id))) then
									--d(tostring(action.name).." was detected immediately.")
									--d("Setting previous skill ID to :"..tostring(castingskill).."["..action.name.."]")
									SkillMgr.prevSkillID = castingskill
									SkillMgr.prevSkillTimestamp = Now()
									if (action.recasttime == 2.5) then
										SkillMgr.prevGCDSkillID = castingskill
									end
									SkillMgr.UpdateLastCast(castingskill)
									if (SkillMgr.UpdateChain(prio,castingskill)) then
										SkillMgr.queuedPrio = 0
									end
									SkillMgr.failTimer = Now() + 6000
								else
									if (skill.chainstart == "1" or skill.chainend == "1") then
										SkillMgr.queuedPrio = prio
									end
								end
								
								return true
							else
								if (gSkillManagerQueueing == "1") then
									SkillMgr.DebugOutput(prio, "Skill failed to cast.")
									return false
								end
							end
						end
					end
				end
			else
				if (IsCaster(Player.job)) then
					local realskilldata = ActionList:Get(skill.id)
					if ( realskilldata and not realskilldata.isready and skill.mplock == "1") then
						if ( (realskilldata.cost > Player.mp.current) or (tonumber(skill.ppowl) > 0 and tonumber(skill.ppowl) > Player.mp.current) ) then
							SkillMgr.mplock = true
							SkillMgr.mplockTimer = Now() + 10000
							SkillMgr.mplockPercent = tonumber(skill.mplockper)
						end
					end
				end
			end
		end
	end
end

SkillMgr.MatchingCraftSkills = {
	--Basic Skills
	-- CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL
	["Basic Synth"] 	={[8] = 100001, [9] = 100015, [10] = 100030, [11] = 100075, [12] = 100045, [13] = 100060, [14] = 100090, [15] = 100105 },
	["Basic Touch"] 	={[8] = 100002, [9] = 100016, [10] = 100031, [11] = 100076, [12] = 100046, [13] = 100061, [14] = 100091, [15] = 100106 },
	["Masters Mend"] 	={[8] = 100003, [9] = 100017, [10] = 100032, [11] = 100077, [12] = 100047, [13] = 100062, [14] = 100092, [15] = 100107 },
	["Standard Touch"] 	={[8] = 100004, [9] = 100018, [10] = 100034, [11] = 100078, [12] = 100048, [13] = 100064, [14] = 100093, [15] = 100109 },
	["Mend II"]   		={[8] = 100005, [9] = 100019, [10] = 100035, [11] = 100079, [12] = 100049, [13] = 100065, [14] = 100094, [15] = 100110 },
	["Standard Synth"] 	={[8] = 100007, [9] = 100021, [10] = 100037, [11] = 100080, [12] = 100051, [13] = 100067, [14] = 100096, [15] = 100111 },
	["Advanced Touch"] 	={[8] = 100008, [9] = 100022, [10] = 100038, [11] = 100081, [12] = 100052, [13] = 100068, [14] = 100097, [15] = 100112 },
	["Observe"]        	={[8] = 100010, [9] = 100023, [10] = 100040, [11] = 100082, [12] = 100053, [13] = 100070, [14] = 100099, [15] = 100113 },
	["Byregots Brow"] 	={[8] = 100120, [9] = 100121, [10] = 100122, [11] = 100123, [12] = 100124, [13] = 100125, [14] = 100126, [15] = 100127 },
	["Precise Touch"]  	={[8] = 100128, [9] = 100129, [10] = 100130, [11] = 100131, [12] = 100132, [13] = 100133, [14] = 100134, [15] = 100135 },
	["Innovative"]  	={[8] = 100137, [9] = 100138, [10] = 100139, [11] = 100140, [12] = 100141, [13] = 100142, [14] = 100143, [15] = 100144 },
	["Byregots Miracle"]={[8] = 100145, [9] = 100146, [10] = 100147, [11] = 100148, [12] = 100149, [13] = 100150, [14] = 100151, [15] = 100152 },
	["Nymeias Wheel"]  	={[8] = 100153, [9] = 100154, [10] = 100155, [11] = 100156, [12] = 100157, [13] = 100158, [14] = 100159, [15] = 100160 },
	["Trained Hand"]  	={[8] = 100161, [9] = 100162, [10] = 100163, [11] = 100164, [12] = 100165, [13] = 100166, [14] = 100167, [15] = 100168 },
	["Satisfaction"]  	={[8] = 100169, [9] = 100170, [10] = 100171, [11] = 100172, [12] = 100173, [13] = 100174, [14] = 100175, [15] = 100176 },
	["Heart"]  			={[8] = 100179, [9] = 100180, [10] = 100181, [11] = 100182, [12] = 100183, [13] = 100184, [14] = 100185, [15] = 100186 },
	["Whistle Work"]  	={[8] = 100187, [9] = 100188, [10] = 100189, [11] = 100190, [12] = 100191, [13] = 100192, [14] = 100193, [15] = 100194 },
	
	["Steady Hand"] = 	{[8] = 244, [9] = 245, [10] = 246, [11] = 247, [12] = 249, [13] = 248, [14] = 250, [15] = 251 },
	["Inner Quiet"] = 	{[8] = 252, [9] = 253, [10] = 254, [11] = 255, [12] = 257, [13] = 256, [14] = 258, [15] = 259 },
	["Great Strides"] = {[8] = 260, [9] = 261, [10] = 262, [11] = 263, [12] = 265, [13] = 264, [14] = 266, [15] = 267 },
}

SkillMgr.lastquality = 0
SkillMgr.currentSHStack = 0
SkillMgr.currentIQStack = 0
SkillMgr.currentToTUses = 0
SkillMgr.currentHTSuccesses = 0
SkillMgr.manipulationUses = 0
SkillMgr.checkHT = false
SkillMgr.newCraft = true
function SkillMgr.Craft()
	-- This is required to refresh the available action list abilities.
	local al = ActionList("type=8")
	
    local synth = Crafting:SynthInfo()
    if ( ValidTable(synth) and ValidTable(SkillMgr.SkillProfile) and not ActionList:IsCasting()) then
		
		if (SkillMgr.newCraft) then
			SkillMgr.currentIQStack = 0 
			SkillMgr.currentSHStack = 0
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
		
		-- Update IQ Stacks
		if (HasBuffs(Player,"251")) then
			if (SkillMgr.currentIQStack == 0) then
				SkillMgr.currentIQStack = 1
			elseif ( synth.quality > SkillMgr.lastquality) then
				SkillMgr.currentIQStack = SkillMgr.currentIQStack + 1
			end
		else
			SkillMgr.currentIQStack = 0 
		end
		
        for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			local skillid = tonumber(skill.id)
			
            if ( skill.used == "1" ) then                
                local realskilldata = ActionList:Get(skillid,9,Player.id)
				local skid = skillid
				--if skill is not found, see if we can find it
				if (not realskilldata) then
					for skillname,data in pairs(SkillMgr.MatchingCraftSkills) do
						for job, sid in pairs(data) do
							if (sid == skill.id) then
								skid = tonumber(data[Player.job]) or 0
								realskilldata = ActionList:Get(skid,9,Player.id)
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

                if ( realskilldata and realskilldata.isready ) then
                    local castable = true
                    if ((tonumber(skill.stepmin) > 0 and synth.step >= tonumber(skill.stepmin)) or
                        (tonumber(skill.stepmax) > 0 and synth.step < tonumber(skill.stepmax)) or
                        (tonumber(skill.cpmin) > 0 and Player.cp.current >= tonumber(skill.cpmin)) or
                        (tonumber(skill.cpmax) > 0 and Player.cp.current < tonumber(skill.cpmax)) or
                        (tonumber(skill.durabmin) > 0 and synth.durability >= tonumber(skill.durabmin)) or
                        (tonumber(skill.durabmax) > 0 and synth.durability < tonumber(skill.durabmax)) or
                        (tonumber(skill.progrmin) > 0 and synth.progress >= tonumber(skill.progrmin)) or
                        (tonumber(skill.progrmax) > 0 and synth.progress < tonumber(skill.progrmax)) or
                        (tonumber(skill.qualitymin) > 0 and synth.quality >= tonumber(skill.qualitymin)) or
                        (tonumber(skill.qualitymax) > 0 and synth.quality < tonumber(skill.qualitymax)) or
                        (tonumber(skill.qualityminper) > 0 and synth.qualitypercent >= tonumber(skill.qualityminper)) or
                        (tonumber(skill.qualitymaxper) > 0 and synth.qualitypercent < tonumber(skill.qualitymaxper)) or
                        (tonumber(skill.iqstack) > 0 and SkillMgr.currentIQStack < tonumber(skill.iqstack)) or
                        (skill.condition ~= "NotUsed" and synth.description ~= skill.condition))							 
                    then 
						castable = false 
                    end
					
					if ((tonumber(skill.totmin) > 0 and SkillMgr.currentToTUses < tonumber(skill.totmin)) or
						(tonumber(skill.totmax) > 0 and SkillMgr.currentToTUses >= tonumber(skill.totmax)))
					then
						castable = false
					end
					
					if (tonumber(skill.htsucceed) > 0 and SkillMgr.currentHTSuccesses > tonumber(skill.htsucceed)) then
						castable = false
					end
					
					if (tonumber(skill.shstackmin) > 0 and SkillMgr.currentSHStack < tonumber(skill.shstackmin)) then
						castable = false
					end
					
					if (tonumber(skill.manipmax) > 0 and SkillMgr.manipulationUses >= tonumber(skill.manipmax)) then
						castable = false
					end
                        
					-- buff checks
                    if ( skill.cpbuff ~= "" ) then
						if not HasBuffs(Player, skill.cpbuff) then
							castable = false 
						end
                    end						
                    
                    if (skill.cpnbuff ~= "" ) then
						if not MissingBuffs(Player, skill.cpnbuff) then
							castable = false 
						end								
                    end								
					
					local currentQuality = synth.quality
					if ( castable ) then
						d("CASTING(Crafting): "..tostring(skill.name))	
						if ( ActionList:Cast(skid,0) ) then	
							SkillMgr.lastquality = currentQuality
							
							if (skid == 100098) then
								SkillMgr.currentToTUses = SkillMgr.currentToTUses + 1
							elseif (skid == 100108) then
								SkillMgr.checkHT = true
							elseif (skid == 278) then
								SkillMgr.manipulationUses = SkillMgr.manipulationUses + 1
							end
							
							if (MultiComp(skid,"281,244,245,246,247,249,248,250,251")) then
								SkillMgr.currentSHStack = 5
							else
								if (SkillMgr.currentSHStack > 0) then
									SkillMgr.currentSHStack = SkillMgr.currentSHStack - 1
								end
							end
							
							SkillMgr.SkillProfile[prio].lastcast = Now()
							SkillMgr.prevSkillID = tostring(skill.id)
							return true
						end	
					end
                end
            end
        end
    end
	return false
end

function SkillMgr.Gather(item)
	-- This is required to refresh the available action list abilities.
	local al = ActionList("type=1")
	
    local node = Player:GetTarget()
    if ( ValidTable(node) and node.cangather and ValidTable(SkillMgr.SkillProfile) and not ActionList:IsCasting()) then
        
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			local skillid = tonumber(skill.id)
            if ( skill.used == "1" ) then		-- takes care of los, range, facing target and valid target		
                local realskilldata = ActionList:Get(skillid,1,Player.id)
                if ( realskilldata and realskilldata.isready ) then 
					local castable = true
					
					if ( tonumber(skill.gsecspassed) > 0 and skill.lastcast ) then
						if (TimeSince(skill.lastcast) < (tonumber(skill.gsecspassed) * 1000)) then 
							castable = false
						end
					end
					
					if ((tonumber(skill.gpmin) > 0 and Player.gp.current > tonumber(skill.gpmin)) or
						(tonumber(skill.gpmax) > 0 and Player.gp.current < tonumber(skill.gpmax)) or
						(tonumber(skill.gatherattempts) > 0 and node.gatherattempts <= tonumber(skill.gatherattempts)) or
						(tonumber(skill.gatherattemptsmax) > 0 and node.gatherattempts > tonumber(skill.gatherattemptsmax)) or
						(skill.hasitem ~="" and not NodeHasItem(skill.hasitem)) or
						(skill.isunspoiled == "1" and not IsUnspoiled(node.contentid)))
						then castable = false 
					end
					
					if (tonumber(skill.itemchancemax) > 0 and item and item.chance > tonumber(skill.itemchancemax)) then
						castable = false
					end
					
					if (tonumber(skill.itemhqchancemin) > 0 and item and (item.hqchance == 255 or item.hqchance < tonumber(skill.itemhqchancemin))) then
						castable = false
					end
					
					if ( skill.gpbuff and skill.gpbuff ~= "" ) then
						local gbfound = HasBuffs(Player,skill.gpbuff)
						if not gbfound then castable = false end
					end

					if (skill.gpnbuff ~= "" ) then
						if not MissingBuffs(Player, skill.gpnbuff) then
							castable = false 
						end								
                    end	
					
					if (SkillMgr.prevSkillList[skillid]) then
						castable = false
					end
					
					if ( castable ) then
						if ( ActionList:Cast(skillid,Player.id)) then	
							--d("CASTING (gathering) : "..tostring(skill.name))
							SkillMgr.SkillProfile[prio].lastcast = Now()
							SkillMgr.prevSkillID = tostring(skillid)
							--After a skill is used here, mark it unusable for the rest of the duration of the node.
							SkillMgr.prevSkillList[skillid] = true
							
							if IsUncoverSkill(skillid) then
								ml_task_hub:CurrentTask().itemsUncovered = true
							end
							return true
						end	
					end					
                end
            end
        end
    end
    return false
end

function SkillMgr.GCDTimeLT(mintime)
	local mintime = tonumber(mintime) or 2.5
	local castable = false
	local actionID = SkillMgr.GCDSkills[Player.job]
	
	if (actionID) then
		local action = ActionList:Get(actionID)
		if (action.cd - action.cdmax) < mintime then
			return true
		end
	else
		return false
	end
	
	return false
end

function SkillMgr.IsGCDReady(maxtime)
	local maxtime = tonumber(maxtime) or .5
	local castable = false
	local timediff = 0
	
	local actionID = SkillMgr.GCDSkills[Player.job]
	
	if (actionID) then
		local action = ActionList:Get(actionID)
		timediff = (action.cd - action.cdmax)
		if (action.cd - action.cdmax) < maxtime then
			castable = true
		end
	else
		castable = true
	end
	
	return castable, timediff
end

function SkillMgr.IsReady( actionid, actiontype )
	actionid = tonumber(actionid)
	actiontype = actiontype or 1
	
	local action = ActionList:Get(actionid, actiontype)
	if (action) then
		return action.isready
	end
	
	return false
end

function SkillMgr.GetCDTime( actionid, actiontype )
	local actionid = tonumber(actionid)
	local actiontype = actiontype or 1
	
	local action = ActionList:Get(actionid, actiontype)
	if (action) then
		return (action.cd - action.cdmax)
	end
	
	return nil
end

function SkillMgr.Use( actionid, targetid, actiontype )
	actiontype = actiontype or 1
	local tid = targetid or Player.id
	
	local action = ActionList:Get(actionid,actiontype,tid)
	if (action and action.isready2 and (gAssistAutoFace == "1" or action.notfacing)) then
		action:Cast(tid)
	end
end

function SkillMgr.DebugOutput( prio, message )
	local prio = tonumber(prio) or 0
	local message = tostring(message)
	
	if (gSkillManagerDebug == "1") then
		if (not gSkillManagerDebugPriorities or gSkillManagerDebugPriorities == "") then
			d("[SkillManager] : " .. message)
		else
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
	
	if (skill.trg == "Target") then
		if (target.id == Player.id) then
			return nil
		end
	elseif ( skill.trg == "Tankable Target") then
		local newtarget = SkillMgr.GetTankableTarget(maxrange)
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == "Tanked Target") then
		local newtarget = SkillMgr.GetTankedTarget(maxrange)
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == "Pet" ) then
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
	elseif ( skill.trg == "Party" ) then
		if ( not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
			local newtarget = PartyMemberWithBuff(skill.ptbuff, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			 else
				return nil
			end
		elseif (skill.ptkbuff == "1") then
			local newtarget = PartyMemberWithBuff(SkillMgr.knownDebuffs, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			 else
				return nil
			end
		else
			local ally = nil
			if ( skill.npc == "1" ) then
				ally = GetBestPartyHealTarget( true, maxrange )
			else
				ally = GetBestPartyHealTarget( false, maxrange )
			end
			
			if ( ally ) then
				target = ally
				TID = ally.id
			else
				return nil
			end
		end
	elseif ( skill.trg == "PartyS" ) then
		if (not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
			local newtarget = PartySMemberWithBuff(skill.ptbuff, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			else
				return nil
			end
		elseif (skill.ptkbuff == "1") then
			local newtarget = PartySMemberWithBuff(SkillMgr.knownDebuffs, skill.ptnbuff, maxrange)
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
	elseif ( skill.trg == "Tank" ) then
		local ally = GetBestTankHealTarget( maxrange )
		if ( ally and ally.id ~= PID) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == "Ally" ) then
		local ally = nil
		if ( skill.npc == "1" ) then
			ally = GetBestHealTarget( true, maxrange )
		else
			ally = GetBestHealTarget( false, maxrange )
		end
		
		if ( ally and ally.id ~= PID) then
			target = ally
			TID = ally.id
		end	
	elseif ( skill.trg == "Dead Party" or skill.trg == "Dead Ally") then
		local ally = nil
		if (skill.trg == "Dead Party") then
			ally = GetBestRevive( true, skill.trgtype )
		else
			ally = GetBestRevive( false, skill.trgtype )
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
	elseif ( skill.trg == "Casting Target" ) then
		local ci = entity.castinginfo
		if ( ci ) then
			target = EntityList:Get(ci.channeltargetid)
			TID = ci.channeltargetid
		else
			return nil
		end
	elseif ( skill.trg == "SMN DoT" ) then
		local newtarget = GetBestDoTTarget()
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == "SMN Bane" ) then
		local newtarget = GetBestBaneTarget()
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == "Player" ) then
		TID = PID
	elseif ( skill.trg == "Low TP" ) then
		local ally = GetLowestTPParty( maxrange, skill.trgtype )
		if ( ally ) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == "Low MP" ) then
		local ally = GetLowestMPParty( maxrange, skill.trgtype )
		if ( ally ) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == "Heal Priority" and tonumber(skill.hpriohp) > 0 ) then
		local priorities = {
			[1] = skill.hprio1,
			[2] = skill.hprio2,
			[3] = skill.hprio3,
			[4] = skill.hprio4,
		}
		
		local healTargets = {}
		healTargets["Self"] = Player
		healTargets["Tank"] = GetBestTankHealTarget( maxrange )
		if ( skill.npc == "1" ) then
			healTargets["Party"] = GetBestPartyHealTarget( true, maxrange )
			healTargets["Any"] = GetBestHealTarget( true, maxrange )
		else
			healTargets["Party"] = GetBestPartyHealTarget( false, maxrange )
			healTargets["Any"] = GetBestHealTarget( false, maxrange ) 
		end
		
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Self] Contains : "..(healTargets["Self"] and healTargets["Self"].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Tank] Contains : "..(healTargets["Tank"] and healTargets["Tank"].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Party] Contains : "..(healTargets["Party"] and healTargets["Party"].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Any] Contains : "..(healTargets["Any"] and healTargets["Any"].name or "nil")..".")
		
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
	
	if (ValidTable(target) and TID ~= 0) then
		targetTable.target = target
		targetTable.TID = TID
		return targetTable
	end
	
	return nil
end

function SkillMgr.CanCast(prio, entity, outofcombat)
	if (not entity) then
		return 0
	end
	
	--Check for buffs on the player that prevent using weaponskills
	if (HasBuffs(Player,"2,3,6")) then
		return 0
	end
	
	outofcombat = outofcombat or false	
	SkillMgr.preCombat = outofcombat
	
	local prio = tonumber(prio) or 0
	if (prio == 0) then
		return 0
	end
	
	local skill = SkillMgr.SkillProfile[prio]
	if (not skill) then
		return 0
	elseif (skill and skill.used == "0") then
		return 0
	end
	
	local skillid = tonumber(skill.id)

	--Pull the real skilldata, if we can't find it, consider it uncastable.
	local realskilldata = nil	
	if (skill.stype == "Pet") then 
		realskilldata = ActionList:Get(skillid,11) 
	else 
		realskilldata = ActionList:Get(skillid,1) 
	end
	if (not realskilldata) then
		return 0
	end
	
	--Some special processing for mudras.
	if (IsMudraSkill(skillid)) then
		dependentskill = ActionList:Get(2260)
		if (not dependentskill or (dependentskill and dependentskill.isoncd)) then
			return 0
		end
	end
	
	if (Player.ismounted) then
		return 0
	end
	
	if (realskilldata.recasttime ~= 2.5) then
		if (TimeSince(SkillMgr.latencyTimer) < 300 or (SkillMgr.queuedPrio ~= 0 and TimeSince(SkillMgr.latencyTimer) < 1000)) then
			return 0
		end
	end
	
	--Check the latency timer to see if casting is currently allowed.
	if (Now() < SkillMgr.latencyTimer or Player.ismounted) then
		return 0
	end
	
	--if ( realskilldata.isready or (realskilldata.recasttime == 2.5 and SkillMgr.IsGCDReady()) or (IsCaster(Player.job) and SkillMgr.IsGCDReady())) then
	local castable = true
	
	local maxrange = realskilldata.range
	if (skill.stype == "Pet") then
		petRangeRadius = GetPetSkillRangeRadius(skill.id)
		if (petRangeRadius) then
			maxrange = petRangeRadius.range
		end
	end
	
	local targetTable = SkillMgr.GetSkillTarget(skill, entity, maxrange)
	if (not targetTable) then
		SkillMgr.DebugOutput( prio, "Target function returned no valid target. : "..tostring(prio))
		return 0
	end
	
	-- Just in case, these shouldn't happen.
	if (not ValidTable(targetTable.target)) then
		SkillMgr.DebugOutput( prio, "Target function returned an invalid target, should never happen.")
		return 0
	elseif (targetTable.TID == 0) then
		SkillMgr.DebugOutput( prio, "Target function returned 0, should never happen.")
		return 0
	end
	
	--Secondary Get() with proper target ID.
	if (skill.stype == "Pet") then 
		realskilldata = ActionList:Get(skillid,11)
	else 
		realskilldata = ActionList:Get(skillid,1,targetTable.TID) 
	end
	
	SkillMgr.CurrentSkill = skill
	SkillMgr.CurrentSkillData = realskilldata
	SkillMgr.CurrentPet = Player.pet	
	SkillMgr.CurrentTarget = targetTable.target
	SkillMgr.CurrentTID = targetTable.TID
	
	-- Verify that condition list is valid, and that castable hasn't already been flagged false, just to save processing time.
	if (SkillMgr.ConditionList) then
		for i,condition in spairs(SkillMgr.ConditionList) do
			if (type(condition.eval) == "function") then
				if (condition.eval()) then
					castable = false		
					SkillMgr.DebugOutput( prio, "Condition ["..condition.name.."] failed its check for "..skill.name.."["..tostring(prio).."]" )
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
		if (IsMudraSkill(skillid) and TimeSince(skill.lastcast) < 600) then
			castable = false
		end
	end
	
	if (castable) then
		SkillMgr.DebugOutput(prio, "Skill was castable.")
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
		d("Condition4:"..tostring(gTeleport == "1"))
		d("Condition5:"..tostring(not IsDutyLeader() or ffxiv_task_duty.independentMode))
		d("not IsDutyLeader():"..tostring(not IsDutyLeader()))
		d("independent:"..tostring(ffxiv_task_duty.independentMode))
		d("Condition6:"..tostring(SkillMgr.teleCastTimer == 0))
		d("Now():"..tostring(Now()))
		d("castTimer:"..tostring(SkillMgr.teleCastTimer))
		d("Condition7:"..tostring(SkillMgr.IsGCDReady()))
		d("Condition8:"..tostring(target.targetid ~= Player.id))
		--]]
		
		if (ml_global_information.AttackRange < 5 and gUseTelecast == "1" and
			gBotMode == GetString("dutyMode") and target.castinginfo and target.castinginfo.channelingid == 0 and
			gTeleport == "1" and (not IsDutyLeader() or ffxiv_task_duty.independentMode) and SkillMgr.teleCastTimer == 0 and SkillMgr.IsGCDReady()
			and target.targetid ~= Player.id) then
			
			ml_task_hub:CurrentTask().suppressFollow = true
			ml_task_hub:CurrentTask().suppressFollowTimer = Now() + 2500
			
			SkillMgr.teleBack = self.safePos
			Player:Stop()
			GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
			Player:SetFacingSynced(pos.h)
			SkillMgr.teleCastTimer = Now() + 1600
		end
		
		SetFacing(pos.x,pos.y,pos.z)
		SkillMgr.Cast( target )
		
		if (TableSize(SkillMgr.teleBack) > 0 and 
			gBotMode == GetString("dutyMode") and 
			(Now() > SkillMgr.teleCastTimer or (target.castinginfo and target.castinginfo.channelingid ~= 0))) then
			local back = SkillMgr.teleBack
			GameHacks:TeleportToXYZ(back.x, back.y, back.z)
			Player:SetFacingSynced(back.h)
			SkillMgr.teleBack = {}
			SkillMgr.teleCastTimer = 0
		end
    else
        self.targetid = 0
        self.completed = true
    end
end

function ffxiv_task_skillmgrAttack:task_complete_eval()
    local target = Player:GetTarget()
    if (target == nil or not target.alive or not target.attackable or (not InCombatRange(target.id) and Player.castinginfo.channelingid == nil)) then
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
	
	if (not IsDutyLeader() and OnDutyMap() and not IsLoading() and Player.incombat and not ml_task_hub:CurrentTask().suppressFollow) then
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

function SkillMgr.AddDefaultConditions()	
	--[[
	conditional = { name = "Other Queued Skill Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if (ValidTable(SkillMgr.otherQueue)) then
			local queued = SkillMgr.otherQueue
			if (not IsNullString(queued.nskill) or not IsNullString(queued.nskillprio)) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	--]]
	
	conditional = { name = "Chain Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
	
		if (skill.chainstart == "0") then
			if (SkillMgr.currentChain ~= "") then
				if (skill.chainname ~= "") then
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
		
		if ((realskilldata.isready2) and (gAssistUseAutoFace == "1" or realskilldata.isfacing)) then
			return false
		elseif (not realskilldata.isready and realskilldata.recasttime == 2.5 and (gAssistUseAutoFace == "1" or realskilldata.isfacing or skill.trg == "Ground Target") and gSkillManagerQueueing == "1" and SkillMgr.IsGCDReady(.400)) then
			return false
		elseif ((skill.trg == "Ground Target" or skill.type == 11) and realskilldata.isready) then
			return false
		end
		return true
	end
	}
	SkillMgr.AddConditional(conditional)
	
	--[[
	conditional = { name = "Min Range (System Defined)"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local ppos = shallowcopy(Player.pos)
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,target.pos.x,target.pos.y,target.pos.z)
		if (skill.trg == "Target") then
			if ( not IsRanged(Player.job) and realskilldata.range >= 15 and realskilldata.recasttime == 2.5 and dist <= (target.hitradius + 4)) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	--]]
	
	conditional = { name = "Min/Max Range Check (User Defined)"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local ppos = shallowcopy(Player.pos)
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,target.pos.x,target.pos.y,target.pos.z)
		local minRange = tonumber(skill.minRange)
		local maxRange = tonumber(skill.maxRange)
		if (minRange > 0 and dist < minRange) then 
			return true
		elseif (maxRange > 0 and maxRange ~= realskilldata.range and (dist - target.hitradius) > maxRange) then
			return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)

	--[[
	conditional = { name = "Target Range/LOS/Facing Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if (skill.trg == "Target") then
			if (gAssistUseAutoFace == "0") then
				if (not ActionList:CanCast(skill.id,target.id)) then
					return true
				end	
			else
				if (ActionList:CanCast(skill.id,target.id)) then
					return false
				end	
				local myPos = Player.pos
				local tPos = target.pos
				local dist = Distance3D(myPos.x,myPos.y,myPos.z,tPos.x,tPos.y,tPos.z)
				if (not target.los or (dist - target.hitradius) > (realskilldata.range * .95)) then
					return true
				end
			end	
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	--]]
	
	conditional = { name = "Debuff/Buff Latency Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( skill.dobuff == "1" and skill.lastcast) then
			if ((skill.lastcast + 1000) > Now()) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "OffGCD Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if (skill.gcd == "Auto") then
			if (realskilldata.recasttime ~= 2.5) then
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
		elseif (skill.gcd == "True") then
			if ((SkillMgr.IsGCDReady(skill.offgcdtime) and not IsCaster(Player.job))) then
				return true
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Other Skill Ready Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( not IsNullString(skill.skready) ) then

			for _orids in StringSplit(skill.skready,",") do
				local ready = false
				
				for _andid in StringSplit(_orids,"+") do
					ready = false
					local actiontype = (skill.sktype == "Action") and 1 or 11
					if ( SkillMgr.IsReady( tonumber(_andid), actiontype)) then
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
	
			--for skillid in StringSplit(skill.skready,",") do
				--local actiontype = (skill.sktype == "Action") and 1 or 11
				--if ( not SkillMgr.IsReady( tonumber(skillid), actiontype)) then
					--return true
				--end
			--end
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
		if ( not IsNullString(skill.sknready)) then
			local actiontype = (skill.sktype == "Action") and 1 or 11
			if ( SkillMgr.IsReady( tonumber(skill.sknready), actiontype)) then
				return true
			end
		end		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	--[[
	conditional = { name = "Next Skill Priority Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		if ( not IsNullString(SkillMgr.nextSkillPrio)) then
			if ( tonumber(SkillMgr.nextSkillPrio) ~= tonumber(skill.prio) ) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	
	conditional = { name = "Next Skill ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		if ( not IsNullString(SkillMgr.nextSkillID)) then
			if ( tonumber(SkillMgr.nextSkillID) ~= tonumber(skill.id) ) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)	
	--]]

	conditional = { name = "Previous Combo Skill ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( not IsNullString(skill.pcskill)) then
			--if (not IsNullString(SkillMgr.prevComboSkillID)) then
			for skillid in StringSplit(skill.pcskill,",") do
				if (Player.lastcomboid == tonumber(skillid) and Player.combotimeremain > .5) then
					return false
				end
			end
			--end
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
			--if (not IsNullString(SkillMgr.prevComboSkillID)) then
			for skillid in StringSplit(skill.npcskill,",") do
				if (Player.lastcomboid == tonumber(skillid) and Player.combotimeremain > .5) then
					return true
				end
			end
			--end
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
		local target = SkillMgr.CurrentTarget
		
		if ( skill.ptrg ~= "Any" ) then
			if (( skill.ptrg == "Enemy" and (not target or not target.attackable)) or 
				( skill.ptrg == "Player" and (not target or target.type ~= 1))) 
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
		if ( skill.onlysolo == "1" and TableSize(plist) > 0 ) then
			return true
		elseif ( skill.onlyparty == "1" ) then
			if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask():ParentTask()) then
				if (ml_task_hub:CurrentTask():ParentTask().name == "QUEST_DUTYKILL") then
					return false
				end				
			end
			if (TableSize(plist) == 0) then
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
		
		if (skill.punderattack == "1") then
			local list = EntityList("nearest,alive,attackable,targetingme,maxdistance=20")
			if (list) then
				for i,e in pairs(list) do
					if (i and e) then
						return true
					end
				end
			end
		end
		
		if (skill.punderattackmelee == "1") then
			local list = EntityList("nearest,alive,attackable,targetingme,maxdistance=6")
			if (list) then
				for i,e in pairs(list) do
					if (i and e) then
						return true
					end
				end
			end
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
			((skill.combat == "In Combat") and not Player.incombat and skill.trg ~= "Target") or
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
		
		if 	((gAssistFilter1 == "1" and skill.filterone == "Off") or 
			(gAssistFilter1 == "0" and skill.filterone == "On" ) or 
			(gAssistFilter2 == "1" and skill.filtertwo == "Off") or
			(gAssistFilter2 == "0" and skill.filtertwo == "On" ) or
			(gAssistFilter3 == "1" and skill.filterthree == "Off") or
			(gAssistFilter3 == "0" and skill.filterthree == "On" ) or
			(gAssistFilter4 == "1" and skill.filterfour == "Off") or
			(gAssistFilter4 == "0" and skill.filterfour == "On" ) or
			(gAssistFilter5 == "1" and skill.filterfive == "Off") or
			(gAssistFilter5 == "0" and skill.filterfive == "On" ))
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
	
	--[[
	conditional = { name = "MP Lock Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if ( SkillMgr.mplock ) then
			if ( (Player.mp.percent >= tonumber(SkillMgr.mplockPercent)) or Now() > SkillMgr.mplockTimer ) then
				SkillMgr.mplock = false
				SkillMgr.mplockPercent = 0
			else
				if ( skill.mplocked == "1" ) then
					return true
				end
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	--]]
	
	conditional = { name = "Player level checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if (tonumber(skill.levelmin) > 0 and 
			((tonumber(skill.levelmin) > Player.level) or (Player:GetSyncLevel() > 0 and (tonumber(skill.levelmin) > Player:GetSyncLevel()))))
		then
			return true
		elseif (tonumber(skill.levelmax) > 0 and
			((tonumber(skill.levelmax) < Player.level) or (Player:GetSyncLevel() > 0 and (tonumber(skill.levelmax) < Player:GetSyncLevel()))))
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
		
		if ((tonumber(skill.ppowl) > 0 and tonumber(skill.ppowl) > Player.mp.current) or 
			(tonumber(skill.pmppl) > 0 and tonumber(skill.pmppl) > Player.mp.percent)) 
		then 
			--[[
			if (skill.mplock == "1" ) then
				SkillMgr.mplock = true
				SkillMgr.mplockTimer = Now() + 10000
				SkillMgr.mplockPercent = tonumber(skill.mplockper)
			end
			--]]
			return true
		elseif ((tonumber(skill.ppowb) > 0 and tonumber(skill.ppowb) < Player.mp.current) or
				(tonumber(skill.pmppb) > 0 and tonumber(skill.pmppb) < Player.mp.percent)) 
		then 
			return true 
		end			
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	--========================================================
	
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
		
		if ( skill.trg == "Player" ) then								
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

	--======================================================================
	
	conditional = { name = "Target HP Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local thpl = tonumber(skill.thpl) or 0
		local thpb = tonumber(skill.thpb) or 0
		local thpcl = tonumber(skill.thpcl) or 0
		local thpcb = tonumber(skill.thpcb) or 0
		local thpadv = tonumber(skill.thpadv) or 0
		if ((thpl > 0 and thpl > target.hp.percent) or
			(thpb > 0 and thpb < target.hp.percent) or
			(thpcl > 0 and thpcl > target.hp.current) or
			(thpcb > 0 and thpcb < target.hp.current) or
			(thpadv > 0 and (((Player.hp.max * thpadv) > target.hp.max) and target.uniqueid ~= 541))) 
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
		
		if (skill.trgtype ~= GetString("any") and target.job ~= nil) then
			local found = true
			local roleString = GetRoleString(target.job)
			if skill.trgtype ~= roleString then 
				found = false
			end
			if skill.trgtype == "Caster" and IsCaster(target.job) then
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
		
		if (skill.trg ~= "Dead Ally" and skill.trg ~= "Dead Party") then
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
		
		if ( skill.ppos ~= "None" ) then 
			if ((skill.ppos == "Flanking" and not IsFlanking(target)) or
				(skill.ppos == "Behind" and not IsBehind(target)) or
				(skill.ppos == "Front" and not IsFront(target)))
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
				local fate = GetFateByID(target.fateid)
				if (ValidTable(fate)) then
					if (fate.status == 2) then
						if (Player:GetSyncLevel() == 0 and AceLib.API.Fate.RequiresSync(fate.id)) then
							return true
						end
					end
				else
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
			local owner = (skill.tbuffowner == "Player") and PID or nil
			local duration = tonumber(skill.tbuffdura) or 0
			if not HasBuffs(target, skill.tbuff, duration, owner) then 
				return true 
			end 
		end
		if (not IsNullString(skill.tnbuff)) then
			local owner = (skill.tbuffowner == "Player") and PID or nil
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
				local ctid = (skill.tcastonme == "1" and Player.id or nil)
				if ( not isCasting(target, skill.tcastids, casttime, ctid ) ) then
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
		
		if (skill.tecenter == "Auto") then
			if (skill.frontalconeaoe == "1") then
				TID = Player.id
			elseif ((realskilldata.casttime == 0 and realskilldata.recasttime > 2.5) or skill.frontalconeaoe == "1") then
				TID = target.id
			end
		else
			if (skill.tecenter == "Self") then
				TID = Player.id
			elseif (skill.tecenter == "Target") then
				TID = target.id
			end
		end
		
		local tecount = tonumber(skill.tecount) or 0
		local tecount2 = tonumber(skill.tecount2) or 0
		local terange = tonumber(skill.terange) or 5
		
		local tlistAE = nil
		if (tecount > 0 or tecount2 > 0) then
			local targets = {}
			tlistAE = EntityList("alive,attackable,maxdistance="..tostring(terange)..",distanceto="..tostring(TID))
			for i,entity in pairs(tlistAE) do
				table.insert(targets,entity)
			end
			
			--Remove all that are targeting me if it's an enmity AOE.
			for i,entity in pairs(targets) do
				if (skill.enmityaoe == "1" and entity.aggropercentage == 100) then
					targets[i] = nil
				elseif (skill.frontalconeaoe == "1" and not EntityIsFrontWide(entity)) then
					targets[i] = nil
				elseif (skill.tankedonlyaoe == "1" and entity.targetid == 0) then
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
		
		if (ValidTable(tlistAE) and skill.televel ~= "Any") then
			local level = tonumber(Player.level) + tonumber(skill.televel)
			for _, entity in pairs(tlistAE) do
				if entity.level > level then
					return true
				end
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
			if (ValidTable(plistAE)) then
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
		
		if (Player:IsMoving() and skill.ignoremoving == "0") then
			if (realskilldata.casttime > 0) then
				if (not HasBuffs(Player,"167",1)) then
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
end


RegisterEventHandler("Gameloop.Update",SkillMgr.OnUpdate)
RegisterEventHandler("GUI.Item",SkillMgr.ButtonHandler)
RegisterEventHandler("SkillManager.toggle", SkillMgr.ToggleMenu)
RegisterEventHandler("GUI.Update",SkillMgr.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",SkillMgr.ModuleInit)

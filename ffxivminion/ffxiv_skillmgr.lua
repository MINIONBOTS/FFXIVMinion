﻿-- Skillmanager for adv. skill customization
SkillMgr = { }
SkillMgr.version = "v0.5";
SkillMgr.profilepath = GetStartupPath() .. [[\LuaMods\ffxivminion\SkillManagerProfiles\]];
SkillMgr.skillbook = { name = strings[gCurrentLanguage].skillbook, x = 250, y = 50, w = 250, h = 350}
SkillMgr.mainwindow = { name = strings[gCurrentLanguage].skillManager, x = 350, y = 50, w = 250, h = 350}
SkillMgr.editwindow = { name = strings[gCurrentLanguage].skillEditor, w = 250, h = 550}
SkillMgr.editwindow_crafting = { name = strings[gCurrentLanguage].skillEditor_craft, w = 250, h = 550}
SkillMgr.editwindow_gathering = { name = strings[gCurrentLanguage].skillEditor_gather, w = 250, h = 550}
SkillMgr.lasttick = 0
SkillMgr.SkillBook = {}
SkillMgr.SkillProfile = {}
SkillMgr.StoopidEventAlreadyRegisteredList = {}
SkillMgr.prevSkillID = ""
SkillMgr.nextSkillID = ""
SkillMgr.nextFailedTimer = 0
SkillMgr.prevFailedTimer = 0
SkillMgr.teleCastTimer = 0
SkillMgr.teleBack = {}
SkillMgr.copiedSkill = {}

SkillMgr.teleCastSkills = {
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
}

SkillMgr.Variables = {
	SKM_NAME = { default = "", cast = "string", profile = "name", section = "main"},
	SKM_ID = { default = 0, cast = "number", profile = "id", section = "main"},
	SKM_ON = { default = "0", cast = "string", profile = "used", section = "main"},
	SKM_Prio = { default = 0, cast = "number", profile = "prio", section = "main"},
	
	SKM_STYPE = { default = "Action", cast = "string", profile = "stype", section = "fighting"},
	SKM_CHARGE = { default = "0", cast = "string", profile = "charge", section = "fighting" },
	SKM_DOBUFF = { default = "0", cast = "string", profile = "dobuff", section = "fighting" },
	SKM_DOPREV = { default = "0", cast = "string", profile = "doprev", section = "fighting"  },
	SKM_LevelMin = { default = 0, cast = "number", profile = "levelmin", section = "fighting"   },
	SKM_Combat = { default = "In Combat", cast = "string", profile = "combat", section = "fighting"  },
	SKM_PVEPVP = { default = "Both", cast = "string", profile = "pvepvp", section = "fighting" },
	SKM_OnlySolo = { default = "0", cast = "string", profile = "onlysolo", section = "fighting"  },
	SKM_OnlyParty = { default = "0", cast = "string", profile = "onlyparty", section = "fighting"  },
	SKM_FilterOne = { default = "Ignore", cast = "string", profile = "filterone", section = "fighting"  },
	SKM_FilterTwo = { default = "Ignore", cast = "string", profile = "filtertwo", section = "fighting"  },
	SKM_CBreak = { default = "0", cast = "string", profile = "cbreak", section = "fighting"  },
	SKM_MPLock = {default = "0", cast = "string", profile = "mplock", section = "fighting" },
	SKM_MPLocked = {default = "0", cast = "string", profile = "mplocked", section = "fighting" },
	SKM_MPLockPer = {default = 0, cast = "number", profile = "mplockper", section = "fighting" },
	SKM_TRG = { default = strings[gCurrentLanguage].target, cast = "string", profile = "trg", section = "fighting"  },
	SKM_TRGTYPE = { default = "Any", cast = "string", profile = "trgtype", section = "fighting"  },
	SKM_NPC = { default = "0", cast = "string", profile = "npc", section = "fighting"  },
	SKM_PTRG = { default = "Any", cast = "string", profile = "ptrg", section = "fighting"  },
	SKM_HPRIOHP = { default = 0, cast = "number", profile = "hpriohp", section = "fighting"  },
	SKM_HPRIO1 = { default = "None", cast = "string", profile = "hprio1", section = "fighting"  },
	SKM_HPRIO2 = { default = "None", cast = "string", profile = "hprio2", section = "fighting"  },
	SKM_HPRIO3 = { default = "None", cast = "string", profile = "hprio3", section = "fighting"  },
	SKM_HPRIO4 = { default = "None", cast = "string", profile = "hprio4", section = "fighting"  },
	SKM_MinR = { default = 0, cast = "number", profile = "minRange", section = "fighting"   },
	SKM_MaxR = { default = 3, cast = "number", profile = "maxRange", section = "fighting"   },	
	SKM_PHPL = { default = 0, cast = "number", profile = "phpl", section = "fighting"   },
	SKM_PHPB = { default = 0, cast = "number", profile = "phpb", section = "fighting"   },
	SKM_PPowL = { default = 0, cast = "number", profile = "ppowl", section = "fighting"   },
	SKM_PPowB = { default = 0, cast = "number", profile = "ppowb", section = "fighting"   },
	SKM_PMPPL = { default = 0, cast = "number", profile = "pmppl", section = "fighting"   },
	SKM_PMPPB = { default = 0, cast = "number", profile = "pmppb", section = "fighting"   },
	SKM_PTPL = { default = 0, cast = "number", profile = "ptpl", section = "fighting"  },
	SKM_PTPB = { default = 0, cast = "number", profile = "ptpb", section = "fighting"   },
	SKM_PAGL = { default = 0, cast = "number", profile = "pagl", section = "fighting"   },
	SKM_PAGB = { default = 0, cast = "number", profile = "pagb", section = "fighting"   },
	SKM_THPL = { default = 0, cast = "number", profile = "thpl", section = "fighting"   },
	SKM_THPB = { default = 0, cast = "number", profile = "thpb", section = "fighting"   },
	SKM_PTCount = { default = 0, cast = "number", profile = "ptcount", section = "fighting"   },
	SKM_PTHPL = { default = 0, cast = "number", profile = "pthpl", section = "fighting"   },
	SKM_PTHPB = { default = 0, cast = "number", profile = "pthpb", section = "fighting"   },
	SKM_PTMPL = { default = 0, cast = "number", profile = "ptmpl", section = "fighting"   },
	SKM_PTMPB = { default = 0, cast = "number", profile = "ptmpb", section = "fighting"   },
	SKM_PTTPL = { default = 0, cast = "number", profile = "pttpl", section = "fighting"   },
	SKM_PTTPB = { default = 0, cast = "number", profile = "pttpb", section = "fighting"   },
	SKM_PTBuff = { default = "", cast = "string", profile = "ptbuff", section = "fighting"  },
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
	SKM_TERange = { default = 0, cast = "number", profile = "terange", section = "fighting"   },
	SKM_TELevel = { default = "Any", cast = "string", profile = "televel", section = "fighting"  },
	--SKM_TESource = { default = "Target", cast = "string", profile = "tesource", section = "fighting"  },
	SKM_TACount = { default = 0, cast = "number", profile = "tacount", section = "fighting"   },
	SKM_TARange = { default = 0, cast = "number", profile = "tarange", section = "fighting"   },
	SKM_TAHPL = { default = 0, cast = "number", profile = "tahpl", section = "fighting"   },
	SKM_PBuff = { default = "", cast = "string", profile = "pbuff", section = "fighting"  },
	SKM_PBuffDura = { default = 0, cast = "number", profile = "pbuffdura", section = "fighting" },
	SKM_PNBuff = { default = "", cast = "string", profile = "pnbuff", section = "fighting"  },
	SKM_PNBuffDura = { default = 0, cast = "number", profile = "pnbuffdura", section = "fighting"   },
	SKM_TBuffOwner = { default = "Player", cast = "string", profile = "tbuffowner", section = "fighting"  },
	SKM_TBuff = { default = "", cast = "string", profile = "tbuff", section = "fighting"  },
	SKM_TNBuff = { default = "", cast = "string", profile = "tnbuff", section = "fighting"  },
	SKM_TNBuffDura = { default = 0, cast = "number", profile = "tnbuffdura", section = "fighting"   },
	SKM_PSkillID = { default = "", cast = "string", profile = "pskill", section = "fighting"  },
	SKM_NSkillID = { default = "", cast = "string", profile = "nskill", section = "fighting"  },
	SKM_NPSkillID = { default = "", cast = "string", profile = "npskill", section = "fighting"  },
	SKM_SecsPassed = { default = 0, cast = "number", profile = "secspassed", section = "fighting"   },
	SKM_PPos = { default = "None", cast = "string", profile = "ppos", section = "fighting"  },
	SKM_OFFGCD = { default = "0", cast = "string", profile = "offgcd", section = "fighting" },
	
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
	
	SKM_GPMIN = { default = 0, cast = "number", profile = "gpmin", section = "gathering"},
	SKM_GPMAX = { default = 0, cast = "number", profile = "gpmax", section = "gathering"},
	SKM_GAttempts = { default = 0, cast = "number", profile = "gatherattempts", section = "gathering"},
	SKM_ITEM = { default = "", cast = "string", profile = "hasitem", section = "gathering"},
	SKM_GSecsPassed = { default = 0, cast = "number", profile = "gsecspassed", section = "gathering"},
	SKM_GPBuff = { default = "", cast = "string", profile = "gpbuff", section = "gathering"  },
	SKM_GPNBuff = { default = "", cast = "string", profile = "gpnbuff", section = "gathering"  },
}

function SkillMgr.ModuleInit() 	
    if (Settings.FFXIVMINION.gSMactive == nil) then
        Settings.FFXIVMINION.gSMactive = "0"
    end
    if (Settings.FFXIVMINION.gSMlastprofile == nil) then
        Settings.FFXIVMINION.gSMlastprofile = "None"
    end
	
	if (Settings.FFXIVMINION.SMDefaultProfiles == nil) then
		Settings.FFXIVMINION.SMDefaultProfiles = {}
	end
	
    -- Skillbook
    GUI_NewWindow(SkillMgr.skillbook.name, SkillMgr.skillbook.x, SkillMgr.skillbook.y, SkillMgr.skillbook.w, SkillMgr.skillbook.h)
    GUI_NewButton(SkillMgr.skillbook.name,strings[gCurrentLanguage].skillbookrefresh,"SMRefreshSkillbookEvent")
    GUI_UnFoldGroup(SkillMgr.skillbook.name,"AvailableSkills")
    GUI_SizeWindow(SkillMgr.skillbook.name,SkillMgr.skillbook.w,SkillMgr.skillbook.h)
    GUI_WindowVisible(SkillMgr.skillbook.name,false)	
    
    -- SelectedSkills/Main Window
    GUI_NewWindow(SkillMgr.mainwindow.name, SkillMgr.skillbook.x+SkillMgr.skillbook.w,SkillMgr.mainwindow.y,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
    GUI_NewCheckbox(SkillMgr.mainwindow.name,strings[gCurrentLanguage].activated,"gSMactive",strings[gCurrentLanguage].generalSettings)
    GUI_NewCheckbox(SkillMgr.mainwindow.name,strings[gCurrentLanguage].defaultProfile,"gSMDefaultProfile",strings[gCurrentLanguage].generalSettings)
    GUI_NewComboBox(SkillMgr.mainwindow.name,strings[gCurrentLanguage].profile,"gSMprofile",strings[gCurrentLanguage].generalSettings,"")
                
    GUI_NewButton(SkillMgr.mainwindow.name,strings[gCurrentLanguage].saveProfile,"SMSaveEvent")
    RegisterEventHandler("SMSaveEvent",SkillMgr.SaveProfile)
    GUI_NewField(SkillMgr.mainwindow.name,strings[gCurrentLanguage].newProfileName,"gSMnewname",strings[gCurrentLanguage].skillEditor)
    GUI_NewButton(SkillMgr.mainwindow.name,strings[gCurrentLanguage].newProfile,"newSMProfileEvent",strings[gCurrentLanguage].skillEditor)
    RegisterEventHandler("newSMProfileEvent",SkillMgr.CreateNewProfile)
    GUI_UnFoldGroup(SkillMgr.mainwindow.name,strings[gCurrentLanguage].generalSettings)
    GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    GUI_WindowVisible(SkillMgr.mainwindow.name,false)		
                        
    gSMactive = Settings.FFXIVMINION.gSMactive
    gSMnewname = ""
    
    -- EDITOR WINDOW
    GUI_NewWindow(SkillMgr.editwindow.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow.w, SkillMgr.editwindow.h)		
    GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].maMarkerName,"SKM_NAME",strings[gCurrentLanguage].skillDetails)
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmSTYPE,"SKM_STYPE",strings[gCurrentLanguage].skillDetails,"Action,Pet")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmCombat,"SKM_Combat",strings[gCurrentLanguage].skillDetails,"In Combat,Out of Combat,Any")
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].maMarkerID,"SKM_ID",strings[gCurrentLanguage].skillDetails)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].enabled,"SKM_ON",strings[gCurrentLanguage].skillDetails)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmCHARGE,"SKM_CHARGE",strings[gCurrentLanguage].basicDetails)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].appliesBuff,"SKM_DOBUFF",strings[gCurrentLanguage].basicDetails)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmLevelMin,"SKM_LevelMin",strings[gCurrentLanguage].basicDetails) -- Needs a string
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].minRange,"SKM_MinR",strings[gCurrentLanguage].basicDetails)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].maxRange,"SKM_MaxR",strings[gCurrentLanguage].basicDetails)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].prevSkillID,"SKM_PSkillID",strings[gCurrentLanguage].basicDetails)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].prevSkillIDNot,"SKM_NPSkillID",strings[gCurrentLanguage].basicDetails)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmNSkillID,"SKM_NSkillID",strings[gCurrentLanguage].basicDetails)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmCBreak,"SKM_CBreak",strings[gCurrentLanguage].basicDetails)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmGCD,"SKM_OFFGCD",strings[gCurrentLanguage].basicDetails)
	--GUI_NewComboBox(SkillMgr.editwindow.name,"Primary Filter","SKM_FilterOne",strings[gCurrentLanguage].basicDetails, "Ignore,Off,On")
	--GUI_NewComboBox(SkillMgr.editwindow.name,"Secondary Filter","SKM_FilterTwo",strings[gCurrentLanguage].basicDetails, "Ignore,Off,On")
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].onlySolo,"SKM_OnlySolo",strings[gCurrentLanguage].basicDetails)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].onlyParty,"SKM_OnlyParty",strings[gCurrentLanguage].basicDetails)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].secsSinceLastCast,"SKM_SecsPassed",strings[gCurrentLanguage].basicDetails)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerHPGT,"SKM_PHPL",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerHPLT,"SKM_PHPB",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerPowerGT,"SKM_PPowL",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerPowerLT,"SKM_PPowB",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPMPPL,"SKM_PMPPL",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPMPPB,"SKM_PMPPB",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTPL,"SKM_PTPL",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTPB,"SKM_PTPB",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPAGL,"SKM_PAGL",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTPB,"SKM_PAGB",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmMPLock,"SKM_MPLock",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmMPLocked,"SKM_MPLocked",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmMPLockPer,"SKM_MPLockPer",strings[gCurrentLanguage].playerHPMPTP)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTCount,"SKM_PTCount",strings[gCurrentLanguage].party)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTHPL,"SKM_PTHPL",strings[gCurrentLanguage].party)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTHPB,"SKM_PTHPB",strings[gCurrentLanguage].party)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTMPL,"SKM_PTMPL",strings[gCurrentLanguage].party)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTMPB,"SKM_PTMPB",strings[gCurrentLanguage].party)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTTPL,"SKM_PTTPL",strings[gCurrentLanguage].party)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTTPB,"SKM_PTTPB",strings[gCurrentLanguage].party)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHasBuffs,"SKM_PTBuff",strings[gCurrentLanguage].party)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmMissBuffs,"SKM_PTNBuff",strings[gCurrentLanguage].party)
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTRG,"SKM_TRG",strings[gCurrentLanguage].target,"Target,Cast Target,Player,Party,PartyS,Pet,Ally,Tank,Heal Priority,Dead Ally,Dead Party")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTRGTYPE,"SKM_TRGTYPE",strings[gCurrentLanguage].target,"Any,Tank,DPS,Caster,Healer")
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmNPC,"SKM_NPC",strings[gCurrentLanguage].target)
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPTRG,"SKM_PTRG",strings[gCurrentLanguage].target,"Any,Enemy,Player")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmPPos,"SKM_PPos",strings[gCurrentLanguage].target,"None,Flanking,Behind")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetHPGT,"SKM_THPL",strings[gCurrentLanguage].target)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetHPLT,"SKM_THPB",strings[gCurrentLanguage].target)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTHPCL,"SKM_THPCL",strings[gCurrentLanguage].target)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTHPCB,"SKM_THPCB",strings[gCurrentLanguage].target)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTCONTIDS,"SKM_TCONTIDS",strings[gCurrentLanguage].target)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTNCONTIDS,"SKM_TNCONTIDS",strings[gCurrentLanguage].target)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTCASTID,"SKM_TCASTID",strings[gCurrentLanguage].casting)
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTCASTTM,"SKM_TCASTTM",strings[gCurrentLanguage].casting)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTCASTTIME,"SKM_TCASTTIME",strings[gCurrentLanguage].casting)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHPRIOHP,"SKM_HPRIOHP",strings[gCurrentLanguage].healPriority)
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHPRIO1,"SKM_HPRIO1",strings[gCurrentLanguage].healPriority,"Self,Tank,Party,Any,None")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHPRIO2,"SKM_HPRIO2",strings[gCurrentLanguage].healPriority,"Self,Tank,Party,Any,None")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHPRIO3,"SKM_HPRIO3",strings[gCurrentLanguage].healPriority,"Self,Tank,Party,Any,None")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHPRIO4,"SKM_HPRIO4",strings[gCurrentLanguage].healPriority,"Self,Tank,Party,Any,None")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTECount,"SKM_TECount",strings[gCurrentLanguage].aoe)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTECount2,"SKM_TECount2",strings[gCurrentLanguage].aoe)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTERange,"SKM_TERange",strings[gCurrentLanguage].aoe)
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTELevel,"SKM_TELevel",strings[gCurrentLanguage].aoe,"0,2,4,6,Any")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTACount,"SKM_TACount",strings[gCurrentLanguage].aoe)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTARange,"SKM_TARange",strings[gCurrentLanguage].aoe)
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].alliesNearHPLT,"SKM_TAHPL",strings[gCurrentLanguage].aoe)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHasBuffs,"SKM_PBuff",strings[gCurrentLanguage].playerBuffs)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmAndBuffDura,"SKM_PBuffDura",strings[gCurrentLanguage].playerBuffs)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmMissBuffs,"SKM_PNBuff",strings[gCurrentLanguage].playerBuffs)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmOrBuffDura,"SKM_PNBuffDura",strings[gCurrentLanguage].playerBuffs)
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmTBuffOwner,"SKM_TBuffOwner",strings[gCurrentLanguage].targetBuffs, "Player,Any")
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmHasBuffs,"SKM_TBuff",strings[gCurrentLanguage].targetBuffs)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmMissBuffs,"SKM_TNBuff",strings[gCurrentLanguage].targetBuffs)
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].skmOrBuffDura,"SKM_TNBuffDura",strings[gCurrentLanguage].targetBuffs)
    GUI_UnFoldGroup(SkillMgr.editwindow.name,strings[gCurrentLanguage].skillDetails)
	
    GUI_NewButton(SkillMgr.editwindow.name,"DELETE","SMEDeleteEvent")
    GUI_NewButton(SkillMgr.editwindow.name,"DOWN","SMESkillDOWNEvent")	
    GUI_NewButton(SkillMgr.editwindow.name,"UP","SMESkillUPEvent")
	GUI_NewButton(SkillMgr.editwindow.name,"PASTE","SKMPasteSkill")
	GUI_NewButton(SkillMgr.editwindow.name,"COPY","SKMCopySkill")
    GUI_SizeWindow(SkillMgr.editwindow.name,SkillMgr.editwindow.w,SkillMgr.editwindow.h)
    GUI_WindowVisible(SkillMgr.editwindow.name,false)
    
    -- Crafting EDITOR WINDOW
    GUI_NewWindow(SkillMgr.editwindow_crafting.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow_crafting.w, SkillMgr.editwindow_crafting.h)		
    GUI_NewField(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].maMarkerName,"SKM_NAME",strings[gCurrentLanguage].skillDetails)
    GUI_NewField(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].maMarkerID,"SKM_ID",strings[gCurrentLanguage].skillDetails)
    GUI_NewCheckbox(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].enabled,"SKM_ON",strings[gCurrentLanguage].skillDetails)	
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].stepmin,"SKM_STMIN",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].stepmax,"SKM_STMAX",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].cpmin,"SKM_CPMIN",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].cpmax,"SKM_CPMAX",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].durabmin,"SKM_DURMIN",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].durabmax,"SKM_DURMAX",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].progrmin,"SKM_PROGMIN",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].progrmax,"SKM_PROGMAX",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].qualitymin,"SKM_QUALMIN",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].qualitymax,"SKM_QUALMAX",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].qualityminper,"SKM_QUALMINPer",strings[gCurrentLanguage].skillDetails);
    GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].qualitymaxper,"SKM_QUALMAXPer",strings[gCurrentLanguage].skillDetails)   
    
    GUI_NewComboBox(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].condition,"SKM_CONDITION",strings[gCurrentLanguage].skillDetails,strings[gCurrentLanguage].notused..","..strings[gCurrentLanguage].excellent..","..strings[gCurrentLanguage].good..","..strings[gCurrentLanguage].normal..","..strings[gCurrentLanguage].poor)
	GUI_NewField(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].playerHas,"SKM_CPBuff",strings[gCurrentLanguage].skillDetails);
    GUI_NewField(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].playerHasNot,"SKM_CPNBuff",strings[gCurrentLanguage].skillDetails);
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].iqstack,"SKM_IQSTACK",strings[gCurrentLanguage].skillDetails);
	
	GUI_UnFoldGroup(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].skillDetails)
    GUI_NewButton(SkillMgr.editwindow_crafting.name,"DELETE","SMEDeleteEvent")	
    GUI_NewButton(SkillMgr.editwindow_crafting.name,"DOWN","SMESkillDOWNEvent")	
    GUI_NewButton(SkillMgr.editwindow_crafting.name,"UP","SMESkillUPEvent")
    GUI_SizeWindow(SkillMgr.editwindow_crafting.name,SkillMgr.editwindow_crafting.w,SkillMgr.editwindow_crafting.h)
    GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)
    
    -- Gathering EDITOR WINDOW
	-- Fixed buffs with new variable
	GUI_NewWindow(SkillMgr.editwindow_gathering.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow_gathering.w, SkillMgr.editwindow_gathering.h)
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].maMarkerName,"SKM_NAME",strings[gCurrentLanguage].skillDetails)
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].maMarkerID,"SKM_ID",strings[gCurrentLanguage].skillDetails)
	GUI_NewCheckbox(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].enabled,"SKM_ON",strings[gCurrentLanguage].skillDetails)
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].gpmin,"SKM_GPMIN",strings[gCurrentLanguage].skillDetails);
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].gpmax,"SKM_GPMAX",strings[gCurrentLanguage].skillDetails);
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].playerHas,"SKM_GPBuff",strings[gCurrentLanguage].skillDetails);
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].playerHasNot,"SKM_GPNBuff",strings[gCurrentLanguage].skillDetails);
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].gatherAttempts,"SKM_GAttempts",strings[gCurrentLanguage].skillDetails);
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].nodeHas,"SKM_ITEM",strings[gCurrentLanguage].skillDetails);
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].secsSinceLastCast,"SKM_GSecsPassed", strings[gCurrentLanguage].skillDetails)

    GUI_UnFoldGroup(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].skillDetails)
    GUI_NewButton(SkillMgr.editwindow_gathering.name,"DELETE","SMEDeleteEvent")
    GUI_NewButton(SkillMgr.editwindow_gathering.name,"DOWN","SMESkillDOWNEvent")		
    GUI_NewButton(SkillMgr.editwindow_gathering.name,"UP","SMESkillUPEvent")
    GUI_SizeWindow(SkillMgr.editwindow_gathering.name,SkillMgr.editwindow_gathering.w,SkillMgr.editwindow_gathering.h)
    GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)
    
   

    SkillMgr.SkillBook = {}
	SkillMgr.UpdateProfiles()
    SkillMgr.UpdateCurrentProfileData()
    GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
end

function SkillMgr.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		
        if ( k == "gSMactive" ) then			
            Settings.FFXIVMINION[tostring(k)] = v		
		elseif ( k == "gSMprofile" ) then
            gSMactive = "1"					
            GUI_WindowVisible(SkillMgr.editwindow.name,false)
            GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)			
            GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
            SkillMgr.SkillProfile = {}
            SkillMgr.UpdateCurrentProfileData()
            Settings.FFXIVMINION.gSMlastprofile = tostring(v)
        elseif ( k == "gSMDefaultProfile" ) then
            if ( v == "0" ) then
                Settings.FFXIVMINION.SMDefaultProfiles[Player.job] = nil
            elseif ( v == "1" ) then
                if (gSMprofile ~= "" and gSMprofile ~= "None") then
                    Settings.FFXIVMINION.SMDefaultProfiles[Player.job] = gSMprofile
                end
            end
            Settings.FFXIVMINION.SMDefaultProfiles = Settings.FFXIVMINION.SMDefaultProfiles
		end
		
		if (SkillMgr.Variables[tostring(k)] ~= nil and SKM_Prio ~= nil and SKM_Prio > 0) then	
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


function SkillMgr.OnUpdate( event, tick )
    
    if ( gSMactive == "1" ) then		
        if	( tick - SkillMgr.lasttick > 150 ) then
            SkillMgr.lasttick = tick
        end
    end
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
		
		if (string.find(Button,"SKMAddSkill") ~= nil) then
			local key = Button:gsub("SKMAddSkill", "")
			SkillMgr.AddSkillToProfile(key)
		end
		
		if (string.find(Button,"SKMCopySkill") ~= nil) then
			SkillMgr.CopySkill()
		end
		
		if (string.find(Button,"SKMPasteSkill") ~= nil) then
			SkillMgr.PasteSkill()
		end
	end
	
end

function SkillMgr.CreateNewProfile()
    
    -- Delete existing Skills
    GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    gSMprofile = "None"
    Settings.FFXIVMINION.gSMlastprofile = gSMprofile
    gSMnewname = ""	
end

function SkillMgr.SetDefaultProfile()
    local default = Settings.FFXIVMINION.SMDefaultProfiles[Player.job]
    if (default) then
        gSMprofile = default
		gSMDefaultProfile = "1"
        GUI_WindowVisible(SkillMgr.editwindow.name,false)
        GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)	
		GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)		
        GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
        SkillMgr.SkillProfile = {}
        SkillMgr.UpdateCurrentProfileData()
    else
		gSMDefaultProfile = "0"
	end
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
                d("Last Profile found : "..profile)
                found = profile
            end
            i,profile = next ( profilelist,i)
        end		
    else
        d("No Skillmanager profiles found")
    end
	
    gSMprofile_listitems = profiles
	--gDefaultProfile_listitems = profiles
	--gModeProfile_listitems = profiles
    gSMprofile = found
	
	return profiles
end

function SkillMgr.CopySkill()
	local source = SkillMgr.SkillProfile[tonumber(SKM_Prio)]
	SkillMgr.copiedSkill = {}
	local temp = {}
	for k,v in pairs(SkillMgr.Variables) do
		if (v.section ~= "main") then
			temp[v.profile] = source[v.profile]
		end
	end
	SkillMgr.copiedSkill = temp
end

function SkillMgr.PasteSkill()
	local source = SkillMgr.copiedSkill
	for conditional,value in pairs(SkillMgr.SkillProfile[tonumber(SKM_Prio)]) do
		local section = nil
		for k,v in pairs(SkillMgr.Variables) do
			if v.profile == conditional then 
				if v.section ~= "main" then
					_G[tostring(k)] = source[conditional]
				end
			end
		end
	end
	GUI_RefreshWindow(SkillMgr.editwindow.name)
end

--+
function SkillMgr.SaveProfile()
    local filename = ""
    local isnew = false
    -- Save under new name if one was entered
    if ( gSMnewname ~= "" ) then
        filename = gSMnewname
        gSMnewname = ""
        isnew = true
    elseif (gSMprofile ~= nil and gSMprofile ~= "None" and gSMprofile ~= "") then
        filename = gSMprofile
        gSMnewname = ""		
    end
            
    -- Save current Profiledata into the Profile-file 
    if ( filename ~= "" ) then
        d("Saving Profile Data into File: "..filename)
        local string2write = "SKM_SMVersion_1=1\n"
		
		for prio, skill in spairs(SkillMgr.SkillProfile) do
			local job = Player.job
			for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "main") then
					string2write = string2write..tostring(k).."="..(skill[v.profile] ~= nil and skill[v.profile] or v.default).."\n"
				end
			end
            if ( job >= 8 and job <=15 ) then
                --crafting
                for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "crafting") then
						string2write = string2write..tostring(k).."="..(skill[v.profile] ~= nil and skill[v.profile] or v.default).."\n"
					end
				end
            elseif ( job >= 16 and job <=17 ) then
                -- gathering                
                for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "gathering") then
						string2write = string2write..tostring(k).."="..(skill[v.profile] ~= nil and skill[v.profile] or v.default).."\n"
					end
				end				
            else
				for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "fighting") then
						string2write = string2write..tostring(k).."="..(skill[v.profile] ~= nil and skill[v.profile] or v.default).."\n"
					end
				end
            end
            string2write = string2write.."SKM_END=0\n"
            --skID,skill = next (SkillMgr.SkillProfile,skID)
        end
		d(tostring(SkillMgr.profilepath ..filename..".lua"))
		d(filewrite(SkillMgr.profilepath ..filename..".lua",string2write))
        
        if ( isnew ) then
            gSMprofile_listitems = gSMprofile_listitems..","..filename
			gDefaultProfile_listitems = gSMprofile_listitems
			gModeProfile_listitems = gSMprofile_listitems
            gSMprofile = filename
            Settings.FFXIVMINION.gSMlastprofile = filename
        end
    end
end

--+
function SkillMgr.UpdateCurrentProfileData()

	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
	SkillMgr.SkillProfile = {}
	
    if ( gSMprofile ~= nil and gSMprofile ~= "" and gSMprofile ~= "None" ) then
        local profile = fileread(SkillMgr.profilepath..gSMprofile..".lua")
		
		--SkillMgr.SkillListTrans()
		
        if ( TableSize(profile) > 0) then
            local sortedSkillList = {}			
            local newskill = {}	
            local i, line = next (profile)
            
            if ( line ) then
			
                local version
                local _, key, id, value = string.match(line, "(%w+)_(%w+)_(%d+)=(.*)")
                if ( tostring(key) == "SMVersion" and tostring(id) == "1") then
                    version = 1
                end
				
                while i and line do
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
							sortedSkillList = TableInsertSort(sortedSkillList,tonumber(newskill.prio),newskill)
                            newskill = {}
						elseif (SkillMgr.Variables["SKM_"..key] ~= nil) then
							local t = SkillMgr.Variables["SKM_"..key]
							if (t ~= nil) then
								if (t.cast == "number") then
									newskill[t.profile] = tonumber(value)
								elseif (t.cast == "string") then
									if (key == "TRG" and value == "Enemy") then
										newskill[t.profile] = strings[gCurrentLanguage].target
									else
										newskill[t.profile] = tostring(value)
									end
								end
							end
						end
                    else
                        d("Error loading inputline: Key: "..(tostring(key)).." value:"..tostring(value))
                    end				
                    i, line = next (profile,i)
                end
            end
            
            -- Create UI Fields
			if ( TableSize(sortedSkillList) > 0 ) then
				local reorder = 1
				for k,v in spairs(sortedSkillList) do
					v.prio = reorder
					SkillMgr.SkillProfile[reorder] = v
					reorder = reorder + 1
				end
				SkillMgr.RefreshSkillList()
			end
        else
            d("Profile is empty..")
        end		
    else
        d("No new SkillProfile selected!")		
    end
	GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
	GUI_RefreshWindow(SkillMgr.mainwindow.name)
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
	--local SkillList = ActionList("type=1")
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
					SkillMgr.CreateNewSkillBookEntry(i, 11)
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
		
		if (group) then
			GUI_NewButton(SkillMgr.skillbook.name, skName.." ["..skID.."]", "SKMAddSkill"..skID, group)
		else
			GUI_NewButton(SkillMgr.skillbook.name, skName.." ["..skID.."]", "SKMAddSkill"..skID, "AvailableSkills")
		end
		
		SkillMgr.SkillBook[skID] = {["id"] = action.id, ["name"] = action.name, ["type"] = actiontype}	
	else
		ml_error("Action ID:"..tostring(id)..", Type:"..tostring(actiontype).." is not valid and could not be retrieved.")
	end
end

-- Button Handler for Skillbook-skill-buttons
function SkillMgr.AddSkillToProfile(event)
    if (ValidTable(SkillMgr.SkillBook[event])) then
        SkillMgr.CreateNewSkillEntry(SkillMgr.SkillBook[event])
    end
end


--+Rebuilds the UI Entries for the Profile-SkillList
function SkillMgr.RefreshSkillList()	
    if ( TableSize( SkillMgr.SkillProfile ) > 0 ) then
		for prio,skill in spairs(SkillMgr.SkillProfile) do
            GUI_NewButton(SkillMgr.mainwindow.name, tostring(prio)..": "..skill.name.."["..tostring(skill.id).."]", "SKMEditSkill"..tostring(prio),"ProfileSkills")
		end
		GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    end
end

function SkillMgr.CreateNewSkillEntry(skill)
	assert(type(skill) == "table", "CreateNewSkillEntry was called with a non-table value.")
	
	if (not skill.name or not skill.id or not skill.type) then
		return false
	end
	
	local skname = skill.name
	local skID = skill.id
	local job = Player.job
	local newskillprio = TableSize(SkillMgr.SkillProfile)+1
	local bevent = tostring(newskillprio)
	
	GUI_NewButton(SkillMgr.mainwindow.name, tostring(bevent)..": "..skname.."["..tostring(skID).."]", "SKMEditSkill"..tostring(bevent),"ProfileSkills")
	
	SkillMgr.SkillProfile[newskillprio] = {	id = skID, prio = newskillprio, name = skname, used = "1" }
	if (job >= 8 and job <= 15) then
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "crafting") then
				SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
			end
		end
	elseif (job >=16 and job <=17) then
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "gathering") then
				SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
			end
		end
	else
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "fighting") then
				SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
			end
		end
	end		
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
        SkillMgr.visible = false
    else	 
        GUI_WindowVisible(SkillMgr.skillbook.name,true)
        GUI_WindowVisible(SkillMgr.mainwindow.name,true)	
        SkillMgr.visible = true
    end
end

function SkillMgr.IsPetSummonSkill(skillID)
    
    if (	skillID == 165
		or 	skillID == 150
        or 	skillID == 170
        or 	skillID == 180) then
        return true
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

function SkillMgr.Cast( entity , preCombat, forceStop )

	preCombat = preCombat or false
	forceStop = forceStop or false
	
    if ( entity ) then
		-- first check if we're in combat or not for the start combat setting	
		if (not preCombat and gBotMode == strings[gCurrentLanguage].assistMode and gStartCombat == "0" and not Player.incombat) then
			return
		end
		
		local PID = Player.id
		local pbuffs = Player.buffs
		
		local EID = entity.id				
		local ebuffs = entity.buffs
		
		local pet = Player.pet
		local plist = EntityList("myparty")
		local ally = nil
		local allyHP = nil
		local allyMP = nil
		local allyTP = nil
		local plistAE = nil
				
		
		--Check for current target cast preventions first.
		--[[
		local cp = Settings.FFXIVMINION.cpOptions
		for k,v in pairs(cp) do
			if ( v.tcastids ~="" and isCasting(entity, v.tcastids, nil, nil ) ) then
				return false
			elseif (v.tbuffs ~= "" and HasBuffs(entity, v.tbuffs)) then
				return false
			end
		end
		--]]
		
		if ( EID and PID and TableSize(SkillMgr.SkillProfile) > 0 ) then
			for prio,skill in spairs(SkillMgr.SkillProfile) do
				ally = nil
				allyHP = nil
				allyMP = nil
				allyTP = nil
				plistAE = nil
				
				if ( skill.used == "1" ) then		-- takes care of los, range, facing target and valid target		
					local realskilldata 
							
					if (skill.stype == "Pet") then 
						realskilldata = ActionList:Get(skill.id,11) 
					else 
						realskilldata = ActionList:Get(skill.id) 
					end

					if ( realskilldata and realskilldata.isready ) then
						--reset our variables
						target = entity
						TID = EID
						tbuffs = ebuffs
					
						local castable = true
						
						if (skill.name == "Purify" and HasBuffs(Player,"2,3,13,14,280")) then
							d("Castable of purify before any check = "..tostring(castable))
						end
				
						-- soft cooldown for compensating the delay between spell cast and buff applies on target)
						if ( skill.dobuff == "1" and skill.lastcast ~= nil and ( skill.lastcast + (realskilldata.casttime * 1000 + 1000) > ml_global_information.Now) ) then 
							castable = false
						end
						
						if ( skill.offgcd == "1" ) then
							if (SkillMgr.IsGCDReady()) then
								castable = false
							end
						end
						
						-- Next Skill Check
						if ( castable and SkillMgr.nextSkillID ~= "" and SkillMgr.nextFailedTimer ~= 0 and TimeSince(SkillMgr.nextFailedTimer) < 5000 ) then
							if ( SkillMgr.nextSkillID ~= tostring(skill.id) ) then
								castable = false
							end
						end
							
						-- CURRENT TARGET -- mostly to prevent assist mode from spamming all cooldowns if a non-enemy is selected
						if ( castable and skill.ptrg ~= "Any" and (
							( skill.ptrg == "Enemy" and not target.attackable)
							or ( skill.ptrg == "Player" and target.type ~= 1 )						
							)) then castable = false end
							
						-- ONLY SOLO OR PARTY
						if ( skill.onlysolo == "1" and TableSize(plist) > 0 ) then castable = false end
						if ( skill.onlyparty == "1" and TableSize(plist) == 0 ) then castable = false end						
						
						if ((skill.combat == "Out of Combat") and (preCombat == nil or preCombat == false) ) then castable = false end
						if ((skill.combat == "In Combat") and (preCombat == true) ) then castable = false end
						
						--CHECK SKILL FILTERS
						if 	(	(gPrimaryFilter == "1" and skill.filterone == "Off")
							or	(gPrimaryFilter == "0" and skill.filterone == "On" )						
							) then castable = false end
							
						if 	( 	(gSecondaryFilter == "1" and skill.filtertwo == "Off") 
							or 	(gSecondaryFilter == "0" and skill.filtertwo == "On" )
							) then castable = false end
						
						-- SECOND SINCE LAST CAST
						if ( skill.secspassed > 0 and skill.lastcast ~= nil and ( ml_global_information.Now - skill.lastcast < skill.secspassed*1000 )) then castable = false end
						
						-- CHECK FOR MP LOCKS						
						if ( mplock == "1") then
							if ( Player.mp.percent >= tonumber(mplockper) ) then
								mplock = "0"
								mplockper = 0
							else
								if ( skill.mplocked == "1" ) then
									castable = false
								end
							end
						end
							
						-- Player HP/TP
						if ( castable and (
							(skill.levelmin > 0 and ((skill.levelmin > Player.level) or (Player:GetSyncLevel() > 0 and (skill.levelmin > Player:GetSyncLevel())))) --custom
							or (skill.phpl > 0 and skill.phpl > Player.hp.percent)
							or (skill.phpb > 0 and skill.phpb < Player.hp.percent)					
							or (skill.ptpl > 0 and skill.ptpl > Player.tp)
							or (skill.ptpb > 0 and skill.ptpb < Player.tp)	
							)) then castable = false end
						
						-- Player MP -- Separated to check for MP lockout.	
						if ( castable ) then
							if ((skill.ppowl > 0 and skill.ppowl > Player.mp.current) or 
								(skill.pmppl > 0 and skill.pmppl > Player.mp.percent)
								) then castable = false
								if (skill.mplock == "1" ) then
									mplock = "1"
									mplockper = tonumber(skill.mplockper)
								end
							elseif ((skill.ppowb > 0 and skill.ppowb < Player.mp.current) or
									(skill.pmppb > 0 and skill.pmppb < Player.mp.percent)
								) then castable = false 
							end
						end
							
						-- Party TP/MP checks.
						if ( castable ) then
							if ( skill.pthpl ~= 0 or skill.pthpb ~= 0 ) then
								allyHP = GetLowestHPParty( skill )
								
								if ( skill.ptcount == 0 and allyHP ~= nil ) then
									if (( skill.pthpl > 0 and skill.pthpl > allyHP.hp.percent ) or
										( skill.pthpb > 0 and skill.pthpb < allyHP.hp.percent )) then castable = false end
								elseif (skill.ptcount > 0 and not allyHP) then
									castable = false
								else
									castable = false
								end
							end
							if ( skill.ptmpl ~= 0 or skill.ptmpb ~= 0 ) then
								allyMP = GetLowestMPParty()
								if ( allyMP ~= nil ) then
									if (( skill.ptmpl > 0 and skill.ptmpl > allyMP.mp.percent ) or
										( skill.ptmpb > 0 and skill.ptmpb < allyMP.mp.percent )) then castable = false end
								else
									castable = false
								end
							end
							if ( skill.pttpl ~= 0 or skill.pttpb ~= 0 ) then
								allyTP = GetLowestTPParty()
								if ( allyTP ~= nil ) then
									if (( skill.pttpl > 0 and skill.pttpl > allyTP.tp ) or
										( skill.pttpb > 0 and skill.pttpb < allyTP.tp )) then castable = false end
								else
									castable = false
								end
							end						
						end
						
						-- Player BUFFS
						if ( castable ) then 							
							-- dont cast this spell when we have not at least one of the BuffIDs in the skill.pbuff list
							if (skill.pbuff ~= "" ) then
								if ( tonumber(skill.pbuffdura) ~= nil and tonumber(skill.pbuffdura) > 0 ) then
									local tbfound = HasBuffsDura(Player, skill.pbuff, skill.pbuffdura)
									if not tbfound then castable = false end 
								else
									local tbfound = HasBuffs(Player, skill.pbuff)
									if not tbfound then castable = false end
								end	
							end
							-- dont cast this spell when we have aony of the BuffIDs in the skill.pnbuff list
							if (skill.pnbuff ~= "" ) then
								if ( skill.pnbuffdura ~= nil and skill.pnbuffdura ~= 0 ) then
									local tbfound = HasBuffsDura(Player, skill.pnbuff, skill.pnbuffdura)
									if tbfound then castable = false end 
								else
									local tbfound = HasBuffs(Player, skill.pnbuff)
									if tbfound then castable = false end                                                                  
								end						
							end							
						end
											
						-- Party Buffs - Cast-On-Self
						if ( castable ) then
							if ( skill.trg == "Player" ) then								
								if ( skill.ptbuff ~= "" or skill.ptnbuff ~= "" ) then
									local partymemberlist = EntityList("myparty,type=1")
									if ( partymemberlist) then
									   local i,entity = next(partymemberlist)
									   while ( i~=nil and entity~=nil ) do
											if ( 	(skill.ptbuff=="" or not HasBuffs(entity,skill.ptbuff)) and
													(skill.ptnbuff=="" or HasBuffs(entity,skill.ptnbuff)) ) then
												castable = false
											end
											i,entity  = next(partymemberlist,i)  
									   end 
									end
									
									if ( 	(skill.ptbuff=="" or not HasBuffs(Player,skill.ptbuff)) and
											(skill.ptnbuff=="" or HasBuffs(Player,skill.ptnbuff)) ) then
										castable = false
									end	
								end
							end
						end	
						
						--Added a castable check so we don't waste CPU doing all this if it's already failed.
						if (castable) then
							-- SWITCH TARGET FOR PET / ALLY - CHECK
							if ( skill.trg == "Pet" ) then
								if ( pet ~= nil and pet ~= 0) then
									if ( SkillMgr.IsPetSummonSkill(skill.id) ) then castable = false end -- we still have a pet, no need to summon
									target = pet
									TID = pet.id
									tbuffs = pet.buffs
								else	
									--target = Player
									TID = PID
									--tbuffs = pbuffs
								end
							elseif ( skill.trg == "Party" ) then
								if ( skill.ptbuff ~= "" or skill.ptnbuff ~= "" ) then
									local newtarget = PartyMemberWithBuff(skill.ptbuff, skill.ptnbuff,skill.maxRange)
									if (newtarget ~= nil) then
										target = newtarget
										TID = newtarget.id
										tbuffs = newtarget.buffs
									 else
										castable = false
									end
								else
									if ( skill.npc == "1" ) then
										ally = GetBestPartyHealTarget( true, skill.maxRange )
									else
										ally = GetBestPartyHealTarget( false, skill.maxRange )
									end
									
									if ( ally ~= nil ) then
										target = ally
										TID = ally.id
										tbuffs = ally.buffs
									else
										castable = false
									end
								end
							elseif ( skill.trg == "PartyS" ) then
								if ( skill.ptbuff ~= "" or skill.ptnbuff ~= "" ) then
									local newtarget = PartySMemberWithBuff(skill.ptbuff, skill.ptnbuff,skill.maxRange)
									if (newtarget ~= nil) then
										target = newtarget
										TID = newtarget.id
										tbuffs = newtarget.buffs
									else
										castable = false
									end
								else
									ally = GetLowestHPParty( skill )

									if ( ally ~= nil ) then
										target = ally
										TID = ally.id
										tbuffs = ally.buffs
									else
										castable = false
									end
								end
							elseif ( skill.trg == "Tank" ) then
								ally = GetBestTankHealTarget( skill.maxRange )
								if ( ally ~= nil and ally.id ~= PID) then
									target = ally
									TID = ally.id
									tbuffs = ally.buffs
								else
									castable = false
								end
							elseif ( skill.trg == "Ally" ) then
								if ( skill.npc == "1" ) then
									ally = GetBestHealTarget( true, skill.maxRange )
								else
									ally = GetBestHealTarget( false, skill.maxRange )
								end
								
								if ( ally ~= nil and ally.id ~= PID) then
									target = ally
									TID = ally.id
									tbuffs = ally.buffs
								end	
							elseif ( skill.trg == "Dead Party" or skill.trg == "Dead Ally") then
								if (skill.trg == "Dead Party") then
									ally = GetBestRevive( true, skill.trgtype )
								else
									ally = GetBestRevive( false, skill.trgtype )
								end 
								
								if ( ally ~= nil and ally.id ~= PID ) then
									if IsReviveSkill(skill.id) then
										target = ally
										TID = ally.id
										tbuffs = ally.buffs
									else
										--target = Player
										TID = PID
										--tbuffs = pbuffs
									end
								else
									castable = false
								end
							elseif ( skill.trg == "Casting Target" ) then
								local ci = entity.castinginfo
								if ( ci ) then
									target = EntityList:Get(ci.channeltargetid)
									TID = ci.channeltargetid
									tbuffs = target.buffs
								else
									castable = false
								end
							elseif ( skill.trg == "Player" ) then
								--target = Player
								TID = PID
								--tbuffs = pbuffs 
							elseif ( skill.trg == "Heal Priority" and skill.hpriohp > 0 ) then
								
								local healSelection = {}
								if (skill.hprio1 == "Self" or skill.hprio2 == "Self" or skill.hprio3 == "Self" or skill.hprio4 == "Self") then 
									healSelection["Self"] = Player
								end
								if (skill.hprio1 == "Tank" or skill.hprio2 == "Tank" or skill.hprio3 == "Tank" or skill.hprio4 == "Tank") then 
									healSelection["Tank"] = GetBestTankHealTarget( skill.maxRange ) 
								end
								if (skill.hprio1 == "Party" or skill.hprio2 == "Party" or skill.hprio3 == "Party" or skill.hprio4 == "Party") then 
									if ( skill.npc == "1" ) then
										healSelection["Party"] = GetBestPartyHealTarget( true, skill.maxRange )
									else
										healSelection["Party"] = GetBestPartyHealTarget( false, skill.maxRange )
									end
								end
								if (skill.hprio1 == "Any" or skill.hprio2 == "Any" or skill.hprio3 == "Any" or skill.hprio4 == "Any") then 
									if ( skill.npc == "1" ) then
										healSelection["Any"] = GetBestHealTarget( true, skill.maxRange ) 
									else
										healSelection["Any"] = GetBestHealTarget( false, skill.maxRange ) 
									end
								end
								
								local prio1
								local prio2
								local prio3
								local prio4
								
								if (skill.hprio1 ~= "None") then prio1 = healSelection[skill.hprio1] else prio1 = 0 end
								if (skill.hprio2 ~= "None") then prio2 = healSelection[skill.hprio2] else prio2 = 0 end
								if (skill.hprio3 ~= "None") then prio3 = healSelection[skill.hprio3] else prio3 = 0 end
								if (skill.hprio4 ~= "None") then prio4 = healSelection[skill.hprio4] else prio4 = 0 end
								
								if (ally == nil) then
									if (prio1 ~= 0 and prio1 ~= nil and skill.hpriohp > prio1.hp.percent) then
										ally = prio1
									end
								end
								
								if (ally == nil) then
									if (prio2 ~= 0 and prio2 ~= nil and skill.hpriohp > prio2.hp.percent) then
										ally = prio2
									end
								end
								
								if (ally == nil) then
									if (prio3 ~= 0 and prio3 ~= nil and skill.hpriohp > prio3.hp.percent) then
										ally = prio3
									end
								end
								
								if (ally == nil) then
									if (prio4 ~= 0 and prio4 ~= nil and skill.hpriohp > prio4.hp.percent) then
										ally = prio4
									end
								end
								
								if ( ally ~= nil ) then
									target = ally
									TID = ally.id
									tbuffs = ally.buffs
								else
									castable = false
								end
							end
						end
						
						if (castable and skill.trgtype ~= strings[gCurrentLanguage].any and target.job ~= nil) then
							local found = true
                            local roleString = GetRoleString(target.job)
                            if skill.trgtype ~= roleString then 
								found = false
							end
							if skill.trgtype == "Caster" and IsCaster(target.job) then
								found = true
							end
							if not found then castable = false end
                        end
						
						-- DEAD TARGET CHECK
						if (castable and (skill.trg ~= "Dead Ally" and skill.trg ~= "Dead Party")) then
							if ( target.hp.current == 0 ) then
								castable = false
							end
						end
							
						-- RANGE 							
						if ( castable and (
						   (skill.minRange > 0 and target.distance2d < skill.minRange)
						or (skill.maxRange > 3 and target.distance2d > skill.maxRange+target.hitradius+1)--target.distance2d- target.hitradius > skill.maxRange)
						)) then castable = false end
									
						-- POSITIONAL		
						if ( castable and skill.ppos ~= "None" ) then 
							if ( skill.ppos == "Flanking" and not IsFlanking(target)) then
								castable = false
							elseif ( skill.ppos == "Behind" and not IsBehind(target)) then
								castable = false
							end						
						end
					 
						-- PLAYER AGGRO
						if ( castable and (				
							(skill.pagl > 0 and skill.pagl > Player.aggropercentage)
							or (skill.pagb > 0 and skill.pagb < Player.aggropercentage)	
							)) then castable = false end
						
						-- TARGET HEALTH
						if ( castable and (
							(skill.thpl > 0 and skill.thpl > target.hp.percent)
							or (skill.thpb > 0 and skill.thpb < target.hp.percent)
							or (skill.thpcl > 0 and skill.thpcl > target.hp.current)
							or (skill.thpcb > 0 and skill.thpcb < target.hp.current)
							)) then castable = false end			

						
						-- TARGET BUFFS
						if ( castable ) then 							
							-- dont cast this spell when the target has not at least one of the BuffIDs in the skill.tbuff list
							if (skill.tbuff ~= "" ) then
								if ( skill.tbuffowner == "Player" ) then
									local tbfound = HasBuffsFromOwner(target, skill.tbuff, PID)
									if not tbfound then castable = false end
								else
									local tbfound = HasBuffs(target, skill.tbuff)
									if not tbfound then castable = false end
								end
							end
							-- dont cast this spell when the target has any of the BuffIDs in the skill.tnbuff list
							if (skill.tnbuff ~= "" ) then
								if ( skill.tnbuffdura ~= nil and skill.tnbuffdura ~= 0 ) then
									if ( skill.tbuffowner == "Player" ) then
										local tbfound = HasBuffsFromOwnerDura(target, skill.tnbuff, PID, skill.tnbuffdura)
										if tbfound then castable = false end 
									else
										local tbfound = HasBuffsDura(target, skill.tnbuff, skill.tnbuffdura)
										if tbfound then castable = false end
									end
								else
									if (skill.tbuffowner == "Player" ) then
										local tbfound = HasBuffsFromOwner(target, skill.tnbuff, PID)
										if tbfound then castable = false end 
									else
										local tbfound = HasBuffs(target, skill.tnbuff)
										if tbfound then castable = false end
									end
								end
							end							
						end
						
						--if (skill.name == "Arm of the Destroyer") then d("Castable before casting check:"..tostring(castable)) end
						-- CASTING
						local casttime = tonumber(skill.tcasttime)
						if casttime == nil then casttime = 0 end
						
						if (castable and ( casttime > 0 or skill.tcastids ~= "")) then
							if (TableSize(target.castinginfo) == 0) then
								castable = false
							elseif target.castinginfo.channeltime == 0 then
								castable = false
							elseif (skill.tcastids == "" and casttime ~= nil) then
								if target.castinginfo.channeltime < casttime then
									castable = false
								end
							elseif (skill.tcastids ~= "") then								
								local ctid = (skill.tcastonme == "1" and Player.id or nil)
								if ( not isCasting(target, skill.tcastids, casttime, ctid ) ) then
									castable = false
								end
							end
						end
						--if (skill.name == "Arm of the Destroyer") then d("Castable after casting check:"..tostring(castable)) end
						
						-- CONTENT ID
						if (castable) then
							if ( skill.tcontids ~="" and not HasContentID(target, skill.tcontids ) ) then
								castable = false
							end
							if ( skill.tncontids ~="" and HasContentID(target, skill.tncontids) ) then
								castable = false
							end
						end
							
						-- TARGET AE CHECK
						local tlistAE
						local attackTable
						if ( castable and (skill.tecount > 0 or skill.tecount2 > 0) and skill.terange > 0 ) then
							tlistAE = EntityList("alive,attackable,maxdistance="..skill.terange..",distanceto="..TID)
							attackTable = TableSize(tlistAE)
			  
							if ( skill.tecount > 0 and ( attackTable < skill.tecount) ) then
								castable = false
							end
							
							if ( skill.tecount2 > 0 and ( attackTable > skill.tecount2) ) then
								castable = false
							end
						end
						
						--"0,2,4,6,Any"
						-- TARGET AE LEVEL CHECK
						if (castable and ValidTable(tlistAE) and skill.televel ~= "Any") then
							local level = tonumber(Player.level) + tonumber(skill.televel)
							for _, entity in pairs(tlistAE) do
								if entity.level > level then
									castable = false
								end
							end
						end
						
						-- ALLY AE CHECK
						if ( castable and skill.tacount > 0 and skill.tarange > 0) then
							plistAE = EntityList("alive,myparty,maxdistance="..skill.tarange..",distanceto="..TID)
							if (TableSize(plistAE) < skill.tacount) then castable = false end
						end
						
						-- ALLY HEALTH CHECK
						-- If we get into this function than we know that skill.tacount > 0 and skill.tarange > 0
						-- and that tarange has already been checked in the previous conditional
						if ( castable and ValidTable(plistAE) and skill.tahpl > 0 ) then
							local count = 0
							for id, entity in pairs(plistAE) do
								if (entity.hp.current ~= 0 and (entity.hp.percent < skill.tahpl)) then
									count = count + 1
								end
							end
							
							if count < skill.tacount then castable = false end
						end
						
						-- PREVIOUS SKILL
						if ( castable and SkillMgr.prevSkillID ~= "" and skill.pskill ~= "" ) then
							castable = false
							for i in skill.pskill:gmatch("%S+") do --custom
								--d("id:"..i..">"..SkillMgr.prevSkillID.."!!")
								if ( SkillMgr.prevSkillID == i and TimeSince(SkillMgr.prevFailedTimer) < 8000) then
									castable = true
									break
								end
							end
						end
						
						-- PREVIOUS SKILL NOT
						if ( castable and SkillMgr.prevSkillID ~= "" and skill.npskill ~= "" ) then
							for i in skill.npskill:gmatch("%S+") do --custom
								--d("id:"..i..">"..SkillMgr.prevSkillID.."!!")
								if ( SkillMgr.prevSkillID == i) then
									castable = false
									break
								end
							end
						end
												
						-- ISMOVING CHECK
						if( castable) then
							if(Player:IsMoving() and realskilldata.casttime > 0 and not forceStop) then
								castable = false
							end
						end
						
						if ( castable ) then
						-- Noob check for making sure we cast the spell on the correct target (buffs n heals only on us/friends, attacks enemies)
							if (skill.stype == "Pet") then	
								local s = ActionList:Get(skill.id,11)
								local attempt = 1
								
								while (s.isready and attempt <= 25) do
									ActionList:Cast(skill.id,TID,11)
									s = ActionList:Get(skill.id,11)
									attempt = attempt + 1
								end			
							else
								if ( ActionList:CanCast(skill.id,tonumber(TID) )) then -- takes care of los, range, facing target and valid target								
									--d("CASTING : "..tostring(skill.name) .." on "..tostring(target.name))
									--If PVP, forceStop a healer to allow them to cast on self.
									if forceStop then Player:Stop() end
									
									if ( ActionList:Cast(skill.id,TID) ) then									
										skill.lastcast = ml_global_information.Now
										if skill.cbreak == "0" then 
											SkillMgr.prevSkillID = tostring(skill.id) 
											SkillMgr.prevFailedTimer = ml_global_information.Now
										end
										if (skill.nskill ~= "") then
											SkillMgr.nextSkillID = tostring(skill.nskill)
											SkillMgr.nextFailedTimer = ml_global_information.Now
										end
										return true
									end					
								end
							end
						end
					
					elseif ( realskilldata and not realskilldata.isready and skill.mplock == "1") then
						if (realskilldata.cost == nil) then
							--d("Skill:"..skill.name.." shows as having nil cost.")
						elseif ( (realskilldata.cost > Player.mp.current) or (tonumber(skill.ppowl) > 0 and tonumber(skill.ppowl) > Player.mp.current) ) then
							mplock = "1"
							mplockper = tonumber(skill.mplockper)
						end
					end
					
                end
            end
        end
    end
	
end

SkillMgr.lastquality = 0
SkillMgr.currentIQStack = 0
function SkillMgr.Craft()
    local synth = Crafting:SynthInfo()
    if ( TableSize(synth) > 0 and TableSize(SkillMgr.SkillProfile) > 0 and not ActionList:IsCasting()) then

		local pbuffs = Player.buffs
		
		-- update inner quite stack
		local iqfound=false
		if ( TableSize(pbuffs) > 0) then
			for i, buff in pairs(pbuffs) do
                if (buff.id == 251) then
						-- first time we have the buff
					if ( SkillMgr.lastquality == 0 ) then
						SkillMgr.lastquality = synth.quality
					elseif ( synth.quality > SkillMgr.lastquality ) then
						-- second time in here with increased quality -> we gained a stack IQ
						SkillMgr.lastquality = synth.quality
						SkillMgr.currentIQStack = SkillMgr.currentIQStack + 1
					end
					iqfound = true
					break
                end
            end
		end
		-- reset
		if not iqfound then 
			SkillMgr.currentIQStack = 0 
			SkillMgr.lastquality = 0
		end
		
        for prio,skill in pairs(SkillMgr.SkillProfile) do
		
            if ( skill.used == "1" ) then                
                local realskilldata = ActionList:Get(skill.id)
				
                if ( realskilldata and realskilldata.isready ) then
				
                    local castable = true
                    --d("Checking on skill:"..tostring(skill.name).."  "..tostring(synth.durability).." > "..tostring(skill.durabmax) .. ": "..tostring(skill.durabmax > 0 and synth.durability > skill.durabmax))
					--d("Checking on skill:"..tostring(skill.name).."  "..tostring(skill.condition).." > "..tostring(synth.description) .. ": "..tostring(skill.condition ~= "NotUsed" and synth.description ~= skill.condition))
                    if ( (skill.stepmin > 0 and synth.step >= skill.stepmin) or
                        (skill.stepmax > 0 and synth.step < skill.stepmax) or
                        (skill.cpmin > 0 and Player.cp.current >= skill.cpmin) or
                        (skill.cpmax > 0 and Player.cp.current < skill.cpmax) or
                        (skill.durabmin > 0 and synth.durability >= skill.durabmin) or
                        (skill.durabmax > 0 and synth.durability < skill.durabmax) or
                        (skill.progrmin > 0 and synth.progress >= skill.progrmin) or
                        (skill.progrmax > 0 and synth.progress < skill.progrmax) or
                        (skill.qualitymin > 0 and synth.quality >= skill.qualitymin) or
                        (skill.qualitymax > 0 and synth.quality < skill.qualitymax) or
                        (skill.qualityminper > 0 and synth.qualitypercent >= skill.qualityminper) or
                        (skill.qualitymaxper > 0 and synth.qualitypercent < skill.qualitymaxper) or
                        (skill.iqstack > 0 and SkillMgr.currentIQStack < skill.iqstack) or
                        (skill.condition ~= "NotUsed" and synth.description ~= skill.condition))							 
                        then castable = false 
                    end
                        
                  -- buff checks

                    if ( skill.cpbuff ~= "" ) then
                      local bfound = HasBuffs(Player,skill.cpbuff)
                      if not bfound then castable = false end
                    end						
                    
                    -- dont cast this spell when we have any of the BuffIDs in the skill.cpnbuff list
                    if (skill.cpnbuff ~= "" ) then
                        local tbfound = HasBuffs(Player,skill.cpnbuff)
                        if tbfound then castable = false end								
                      end								
	 
							 
                        if ( castable ) then
                          d("CASTING(Crafting) : "..tostring(skill.name))								
                          if ( ActionList:Cast(skill.id,0) ) then									
                            skill.lastcast = ml_global_information.Now
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

function SkillMgr.Gather()

	local node = Player:GetTarget()
	if ( ValidTable(node) and node.cangather and TableSize(SkillMgr.SkillProfile) > 0 and not ActionList:IsCasting()) then

		for prio,skill in pairs(SkillMgr.SkillProfile) do
			if ( skill.used == "1" ) then		-- takes care of los, range, facing target and valid target

				local realskilldata = ActionList:Get(skill.id)
				if ( realskilldata and realskilldata.isready ) then
					if ( realskilldata.isready ) then
						local castable = true
                        
						-- trying this due to TimeSince can't take a nil value first run of skill.lastcast will be nil
						if ( skill.lastcast == nil) then
						d("says lastcast is nil maybe first time so ignoring secs passed this time")
						elseif ( skill.gsecspassed > 0 and (skill.lastcast ~= nil and TimeSince(skill.lastcast) < (skill.gsecspassed * 1000))) then
							castable = false
							end

						--these first two conditionals here look retarded due to poor naming but they are correct
						-- removed player buff checks as they was nil forcing a fail
						if ((skill.gpmin > 0 and Player.gp.current > skill.gpmin) or
						(skill.gpmax > 0 and Player.gp.current < skill.gpmax) or
						(skill.gatherattempts > 0 and node.gatherattempts <= skill.gatherattempts) or
						(skill.hasitem ~= "" and not NodeHasItem(skill.hasitem)))
						then castable = false
						end
						-- inline with the crafting function added buff checks here and added own variables for player buffs to profile for checking
						-- the pbuff and pnbuff didn't save in crafting profile due to them being saved in fighting category causing error in string function from being nil when loading profile

					    if ( skill.gpbuff ~= "" ) then
						local gbfound = HasBuffs(Player,skill.gpbuff)
						if not gbfound then castable = false end
					    end

					    if (skill.gpnbuff ~= "" ) then
						local gtbfound = HasBuffs(Player,skill.gpnbuff)
						if gtbfound then castable = false end
					    end
					
						if ( castable ) then
							d("CASTING (gathering) : "..tostring(skill.name))
							if ( ActionList:Cast(skill.id,0) ) then
								skill.lastcast = ml_global_information.Now
								SkillMgr.prevSkillID = tostring(skill.id)
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

function SkillMgr.TryCast( entity , testprio )
	
	local castable = true
	local failsection = ""
	
    if ( entity ) then
	
		local PID = Player.id
		local pbuffs = Player.buffs
		
		local EID = entity.id				
		local ebuffs = entity.buffs
		
		local pet = Player.pet
		local plist = EntityList.myparty
		local ally = nil
		local allyHP = nil
		local allyMP = nil
		local allyTP = nil
		local plistAE = nil
		
		if ( EID and PID and TableSize(SkillMgr.SkillProfile) > 0 ) then
			for prio,skill in spairs(SkillMgr.SkillProfile) do
				if tonumber(prio) == tonumber(testprio) then
				
					if ( skill.used == "1" ) then	
					local realskilldata 
							
					if (skill.stype == "Pet") then 
						realskilldata = ActionList:Get(skill.id,11) 
					else 
						realskilldata = ActionList:Get(skill.id) 
					end

						if ( realskilldata and realskilldata.isready ) then
							--reset our variables
							target = entity
							TID = EID
							tbuffs = ebuffs
						
							local castable = true
							local failsection = ""
					
							-- soft cooldown for compensating the delay between spell cast and buff applies on target)
							if ( skill.dobuff == "1" and skill.lastcast ~= nil and ( skill.lastcast + (realskilldata.casttime * 1000 + 1000) > ml_global_information.Now) ) then 
								castable = false
								failsection = "buffCooldown"
							end
							
							if ( skill.offgcd == "1" and SkillMgr.IsGCDReady()) then
								castable = false
							end
							
							-- Next Skill Check
							if ( castable and SkillMgr.nextSkillID ~= "" and SkillMgr.nextFailedTimer ~= 0 and TimeSince(SkillMgr.nextFailedTimer) < 5000 ) then
								if ( SkillMgr.nextSkillID ~= tostring(skill.id) ) then
									castable = false
									failsection = "nextSkillcheck"
								end
							end
								
							-- CURRENT TARGET -- mostly to prevent assist mode from spamming all cooldowns if a non-enemy is selected
							if ( castable and skill.ptrg ~= "Any" and (
								( skill.ptrg == "Enemy" and not target.attackable)
								or ( skill.ptrg == "Player" and target.type ~= 1 )						
								)) then 
								castable = false 
								failsection = "ptrgType"
							end
								
							-- ONLY SOLO OR PARTY
							
							if (castable) then
								if ( skill.onlysolo == "1" and TableSize(plist) > 0 ) then castable = false end
								if ( skill.onlyparty == "1" and TableSize(plist) == 0 ) then castable = false end
							
								if ((skill.combat == "Out of Combat") and (preCombat == nil or preCombat == false) ) then castable = false end
								if ((skill.combat == "In Combat") and (preCombat == true) ) then castable = false end
								
								if (not castable) then
									failsection = "solo, party, incombat, out of combat"
								end
							end
							
					
							--CHECK SKILL FILTERS
							if (castable) then
								if 	(	(gPrimaryFilter == "1" and skill.filterone == "Off")
									or	(gPrimaryFilter == "0" and skill.filterone == "On" )						
									) then castable = false end
									
								if 	( 	(gSecondaryFilter == "1" and skill.filtertwo == "Off") 
									or 	(gSecondaryFilter == "0" and skill.filtertwo == "On" )
									) then castable = false end
								
								if (not castable) then
									failsection = "skill filters"
								end
							end
							
							-- SECOND SINCE LAST CAST
							if ( castable and skill.secspassed > 0 and skill.lastcast ~= nil and ( ml_global_information.Now - skill.lastcast < skill.secspassed*1000 )) then 
								castable = false 
								failsection = "secs passed"
							end
							
							-- CHECK FOR MP LOCKS	
							if (castable) then
								if ( mplock == "1") then
									if ( Player.mp.percent >= tonumber(mplockper) ) then
										mplock = "0"
										mplockper = 0
									else
										if ( skill.mplocked == "1" ) then
											castable = false
											failsection = "mp lock"
										end
									end
								end
							end
									
							-- Player HP/TP
							if ( castable and (
								(skill.levelmin > 0 and ((skill.levelmin > Player.level) or (Player:GetSyncLevel() > 0 and (skill.levelmin > Player:GetSyncLevel())))) --custom
								or (skill.phpl > 0 and skill.phpl > Player.hp.percent)
								or (skill.phpb > 0 and skill.phpb < Player.hp.percent)					
								or (skill.ptpl > 0 and skill.ptpl > Player.tp)
								or (skill.ptpb > 0 and skill.ptpb < Player.tp)	
								)) then castable = false 
								failsection = "player hp/tp"
							end
							
							-- Player MP -- Separated to check for MP lockout.	
							if ( castable ) then
								if ((skill.ppowl > 0 and skill.ppowl > Player.mp.current) or 
									(skill.pmppl > 0 and skill.pmppl > Player.mp.percent)) then 
									castable = false
									failsection = "player mp not enough"
									if (skill.mplock == "1" ) then
										mplock = "1"
										mplockper = tonumber(skill.mplockper)
									end
								elseif ((skill.ppowb > 0 and skill.ppowb < Player.mp.current) or
										(skill.pmppb > 0 and skill.pmppb < Player.mp.percent)) then 
										castable = false 
										failsection = "player mp too much"
								end
							end
								
							-- Party TP/MP checks.
							if ( castable ) then
								if ( skill.pthpl ~= 0 or skill.pthpb ~= 0 ) then
									if ( skill.npc == "1" ) then
										allyHP = GetLowestHPParty( true, skill.maxRange )
									else
										allyHP = GetLowestHPParty( false, skill.maxRange )
									end
									
									if ( allyHP ~= nil ) then
										if (( skill.pthpl > 0 and skill.pthpl > allyHP.hp.percent ) or
											( skill.pthpb > 0 and skill.pthpb < allyHP.hp.percent )) then castable = false end
									else
										castable = false
									end
								end
								if ( skill.ptmpl ~= 0 or skill.ptmpb ~= 0 ) then
									allyMP = GetLowestMPParty()
									if ( allyMP ~= nil ) then
										if (( skill.ptmpl > 0 and skill.ptmpl > allyMP.mp.percent ) or
											( skill.ptmpb > 0 and skill.ptmpb < allyMP.mp.percent )) then castable = false end
									else
										castable = false
									end
								end
								if ( skill.pttpl ~= 0 or skill.pttpb ~= 0 ) then
									allyTP = GetLowestTPParty()
									if ( allyTP ~= nil ) then
										if (( skill.pttpl > 0 and skill.pttpl > allyTP.tp ) or
											( skill.pttpb > 0 and skill.pttpb < allyTP.tp )) then castable = false end
									else
										castable = false
									end
								end	
								
								if not castable then failsection = "party tp/mp checks" end
							end
							
							-- Player BUFFS
							if ( castable ) then 							
								-- dont cast this spell when we have not at least one of the BuffIDs in the skill.pbuff list
								if (skill.pbuff ~= "" ) then
									if ( tonumber(skill.pbuffdura) ~= nil and tonumber(skill.pbuffdura) > 0 ) then
										local tbfound = HasBuffsDura(Player, skill.pbuff, skill.pbuffdura)
										if not tbfound then castable = false end 
									else
										local tbfound = HasBuffs(Player, skill.pbuff)
										if not tbfound then castable = false end
									end	
								end
								-- dont cast this spell when we have aony of the BuffIDs in the skill.pnbuff list
								if (skill.pnbuff ~= "" ) then
									if ( skill.pnbuffdura ~= nil and skill.pnbuffdura ~= 0 ) then
										local tbfound = HasBuffsDura(Player, skill.pnbuff, skill.pnbuffdura)
										if tbfound then castable = false end 
									else
										local tbfound = HasBuffs(Player, skill.pnbuff)
										if tbfound then castable = false end                                                                  
									end						
								end
								if not castable then failsection = strings[gCurrentLanguage].playerBuffs end
							end

							-- Party Buffs - Cast-On-Self
							if ( castable ) then
								if ( skill.trg == "Player" ) then								
									if ( skill.ptbuff ~= "" or skill.ptnbuff ~= "" ) then
										local partymemberlist = EntityList("myparty,type=1")
										if ( partymemberlist) then
										   local i,entity = next(partymemberlist)
										   while ( i~=nil and entity~=nil ) do
												if ( 	(skill.ptbuff=="" or not HasBuffs(entity,skill.ptbuff)) and
														(skill.ptnbuff=="" or HasBuffs(entity,skill.ptnbuff)) ) then
													castable = false
												end
												i,entity  = next(partymemberlist,i)  
										   end 
										end
										
										if ( 	(skill.ptbuff=="" or not HasBuffs(Player,skill.ptbuff)) and
												(skill.ptnbuff=="" or HasBuffs(Player,skill.ptnbuff)) ) then
											castable = false
										end	
									end
								end
								if not castable then failsection = "party buffs" end
							end	
							
							--Added a castable check so we don't waste CPU doing all this if it's already failed.
							if (castable) then
								-- SWITCH TARGET FOR PET / ALLY - CHECK
								if ( skill.trg == "Pet" ) then
									if ( pet ~= nil and pet ~= 0) then
										if ( SkillMgr.IsPetSummonSkill(skill.id) ) then castable = false end -- we still have a pet, no need to summon
										target = pet
										TID = pet.id
										tbuffs = pet.buffs
									else	
										--target = Player
										TID = PID
										--tbuffs = pbuffs
									end
								elseif ( skill.trg == strings[gCurrentLanguage].party ) then
									if ( skill.ptbuff ~= "" or skill.ptnbuff ~= "" ) then
										local newtarget = PartyMemberWithBuff(skill.ptbuff, skill.ptnbuff,skill.maxRange)
										if (newtarget ~= nil) then
											target = newtarget
											TID = newtarget.id
											tbuffs = newtarget.buffs
										 else
											castable = false
										end
									else
										if ( skill.npc == "1" ) then
											ally = GetBestPartyHealTarget( true, skill.maxRange )
										else
											ally = GetBestPartyHealTarget( false, skill.maxRange )
										end
										
										if ( ally ~= nil ) then
											target = ally
											TID = ally.id
											tbuffs = ally.buffs
										else
											castable = false
										end
									end
								elseif ( skill.trg == "PartyS" ) then
									if ( skill.ptbuff ~= "" or skill.ptnbuff ~= "" ) then
										local newtarget = PartySMemberWithBuff(skill.ptbuff, skill.ptnbuff,skill.maxRange)
										if (newtarget ~= nil) then
											target = newtarget
											TID = newtarget.id
											tbuffs = newtarget.buffs
										else
											castable = false
										end
									else
										if ( skill.npc == "1" ) then
											ally = GetLowestHPParty( true )
										else
											ally = GetLowestHPParty( false )
										end

										if ( ally ~= nil ) then
											target = ally
											TID = ally.id
											tbuffs = ally.buffs
										else
											castable = false
										end
									end
								elseif ( skill.trg == "Tank" ) then
									ally = GetBestTankHealTarget( skill.maxRange )
									if ( ally ~= nil and ally.id ~= PID) then
										target = ally
										TID = ally.id
										tbuffs = ally.buffs
									else
										castable = false
									end
								elseif ( skill.trg == "Ally" ) then
									if ( skill.npc == "1" ) then
										ally = GetBestHealTarget( true, skill.maxRange )
									else
										ally = GetBestHealTarget( false, skill.maxRange )
									end
									
									if ( ally ~= nil and ally.id ~= PID) then
										target = ally
										TID = ally.id
										tbuffs = ally.buffs
									end	
								elseif ( skill.trg == "Dead Party" or skill.trg == "Dead Ally") then
									if (skill.trg == "Dead Party") then
										ally = GetBestRevive( true, skill.trgtype )
									else
										ally = GetBestRevive( false, skill.trgtype )
									end 
									
									if ( ally ~= nil and ally.id ~= PID ) then
										if IsReviveSkill(skill.id) then
											target = ally
											TID = ally.id
											tbuffs = ally.buffs
										else
											--target = Player
											TID = PID
											--tbuffs = pbuffs
										end
									else
										castable = false
									end
								elseif ( skill.trg == "Casting Target" ) then
									local ci = entity.castinginfo
									if ( ci ) then
										target = EntityList:Get(ci.channeltargetid)
										TID = ci.channeltargetid
										tbuffs = target.buffs
									else
										castable = false
									end
								elseif ( skill.trg == "Player" ) then
									--target = Player
									TID = PID
									--tbuffs = pbuffs 
								elseif ( skill.trg == strings[gCurrentLanguage].healPriority and skill.hpriohp > 0 ) then
									
									local healSelection = {}
									if (skill.hprio1 == "Self" or skill.hprio2 == "Self" or skill.hprio3 == "Self" or skill.hprio4 == "Self") then 
										healSelection["Self"] = Player
									end
									if (skill.hprio1 == "Tank" or skill.hprio2 == "Tank" or skill.hprio3 == "Tank" or skill.hprio4 == "Tank") then 
										healSelection["Tank"] = GetBestTankHealTarget( skill.maxRange ) 
									end
									if (skill.hprio1 == strings[gCurrentLanguage].party or skill.hprio2 == strings[gCurrentLanguage].party or skill.hprio3 == strings[gCurrentLanguage].party or skill.hprio4 == strings[gCurrentLanguage].party) then 
										if ( skill.npc == "1" ) then
											healSelection[strings[gCurrentLanguage].party] = GetBestPartyHealTarget( true, skill.maxRange )
										else
											healSelection[strings[gCurrentLanguage].party] = GetBestPartyHealTarget( false, skill.maxRange )
										end
									end
									if (skill.hprio1 == "Any" or skill.hprio2 == "Any" or skill.hprio3 == "Any" or skill.hprio4 == "Any") then 
										if ( skill.npc == "1" ) then
											healSelection["Any"] = GetBestHealTarget( true, skill.maxRange ) 
										else
											healSelection["Any"] = GetBestHealTarget( false, skill.maxRange ) 
										end
									end
									
									local prio1
									local prio2
									local prio3
									local prio4
									
									if (skill.hprio1 ~= "None") then prio1 = healSelection[skill.hprio1] else prio1 = 0 end
									if (skill.hprio2 ~= "None") then prio2 = healSelection[skill.hprio2] else prio2 = 0 end
									if (skill.hprio3 ~= "None") then prio3 = healSelection[skill.hprio3] else prio3 = 0 end
									if (skill.hprio4 ~= "None") then prio4 = healSelection[skill.hprio4] else prio4 = 0 end
									
									if (ally == nil) then
										if (prio1 ~= 0 and prio1 ~= nil and skill.hpriohp > prio1.hp.percent) then
											ally = prio1
										end
									end
									
									if (ally == nil) then
										if (prio2 ~= 0 and prio2 ~= nil and skill.hpriohp > prio2.hp.percent) then
											ally = prio2
										end
									end
									
									if (ally == nil) then
										if (prio3 ~= 0 and prio3 ~= nil and skill.hpriohp > prio3.hp.percent) then
											ally = prio3
										end
									end
									
									if (ally == nil) then
										if (prio4 ~= 0 and prio4 ~= nil and skill.hpriohp > prio4.hp.percent) then
											ally = prio4
										end
									end
									
									if ( ally ~= nil ) then
										target = ally
										TID = ally.id
										tbuffs = ally.buffs
									else
										castable = false
									end
								end
								if not castable then failsection = "target selection" end
							end
							
							if (castable and skill.trgtype ~= strings[gCurrentLanguage].any and target.job ~= nil) then
								local found = true
								local roleString = GetRoleString(target.job)
								if skill.trgtype ~= roleString then 
									found = false
								end
								if skill.trgtype == "Caster" and IsCaster(target.job) then
									found = true
								end
								if not found then castable = false end
								
								if not castable then failsection = "target role/type" end
							end
							
							-- DEAD TARGET CHECK
							if (castable and (skill.trg ~= "Dead Ally" and skill.trg ~= "Dead Party")) then
								if ( target.hp.current == 0 ) then
									castable = false
								end
								if not castable then failsection = "dead party/ally" end
							end
								
							-- RANGE 							
							if ( castable and (
							   (skill.minRange > 0 and target.distance2d < skill.minRange)
							or (skill.maxRange > 3 and target.distance2d > skill.maxRange+target.hitradius+1))) then 
								castable = false 
								failsection = "range"
							end
										
							-- POSITIONAL		
							if ( castable and skill.ppos ~= "None" ) then 
								if ( skill.ppos == "Flanking" and not IsFlanking(target)) then
									castable = false
								elseif ( skill.ppos == "Behind" and not IsBehind(target)) then
									castable = false
								end	
								if not castable then failsection = "positional" end
							end
						 
							-- PLAYER AGGRO
							if ( castable and (				
								(skill.pagl > 0 and skill.pagl > Player.aggropercentage)
								or (skill.pagb > 0 and skill.pagb < Player.aggropercentage))) then 
									castable = false 
									failsection = "aggro"
							end
							
							-- TARGET HEALTH
							if ( castable and (
								(skill.thpl > 0 and skill.thpl > target.hp.percent)
								or (skill.thpb > 0 and skill.thpb < target.hp.percent)
								or (skill.thpcl > 0 and skill.thpcl > target.hp.current)
								or (skill.thpcb > 0 and skill.thpcb < target.hp.current))) then 
									castable = false 
									failsection = "target health"
							end			

							
							-- TARGET BUFFS
							if ( castable ) then 							
								-- dont cast this spell when the target has not at least one of the BuffIDs in the skill.tbuff list
								if (skill.tbuff ~= "" ) then
									if ( skill.tbuffowner == "Player" ) then
										local tbfound = HasBuffsFromOwner(target, skill.tbuff, PID)
										if not tbfound then castable = false end
									else
										local tbfound = HasBuffs(target, skill.tbuff)
										if not tbfound then castable = false end
									end
								end
								-- dont cast this spell when the target has any of the BuffIDs in the skill.tnbuff list
								if (skill.tnbuff ~= "" ) then
									if ( skill.tnbuffdura ~= nil and skill.tnbuffdura ~= 0 ) then
										if ( skill.tbuffowner == "Player" ) then
											local tbfound = HasBuffsFromOwnerDura(target, skill.tnbuff, PID, skill.tnbuffdura)
											if tbfound then castable = false end 
										else
											local tbfound = HasBuffsDura(target, skill.tnbuff, skill.tnbuffdura)
											if tbfound then castable = false end
										end
									else
										if (skill.tbuffowner == "Player" ) then
											local tbfound = HasBuffsFromOwner(target, skill.tnbuff, PID)
											if tbfound then castable = false end 
										else
											local tbfound = HasBuffs(target, skill.tnbuff)
											if tbfound then castable = false end
										end
									end
								end
								
								if not castable then failsection = strings[gCurrentLanguage].targetBuffs end
							end
							
							-- CASTING
							if (castable and tonumber(skill.tcasttime) > 0) then
								local casttime = tonumber(skill.tcasttime)
								if (casttime ~= nil) then 
									if (TableSize(target.castinginfo) == 0) then
										castable = false
									elseif target.castinginfo.channeltime == 0 then
										castable = false
									elseif (skill.tcastids == "" or skill.tcastids == nil) then
										if target.castinginfo.channeltime < casttime then
											castable = false
										end
									elseif (skill.tcastids ~= "") then								
										local ctid = (skill.tcastonme =="1" and Player.id or nil)
										if ( not isCasting(target, skill.tcastids, casttime, ctid ) ) then
											castable = false
										end
									end
								end
								if not castable then failsection = "target casting" end
							end
							
							-- CONTENT ID
							if (castable) then
								if ( skill.tcontids ~="" and not HasContentID(target, skill.tcontids ) ) then
									castable = false
								end
								if ( skill.tncontids ~="" and HasContentID(target, skill.tncontids) ) then
									castable = false
								end
								if not castable then failsection = "content ID" end
							end
								
							-- TARGET AE CHECK
							local tlistAE
							local attackTable
							if ( castable and (skill.tecount > 0 or skill.tecount2 > 0) and skill.terange > 0 ) then
								tlistAE = EntityList("alive,attackable,maxdistance="..skill.terange..",distanceto="..target.id)
								attackTable = TableSize(tlistAE)
				  
								if ( skill.tecount > 0 and ( attackTable < skill.tecount) ) then
									castable = false
								end
								
								if ( skill.tecount2 > 0 and ( attackTable > skill.tecount2) ) then
									castable = false
								end
								if not castable then failsection = "target AOE check" end
							end
							
							-- TARGET AE LEVEL CHECK
							if (castable and ValidTable(tlistAE) and skill.televel ~= "Any") then
								local level = tonumber(Player.level) + tonumber(skill.televel)
								for _, entity in pairs(tlistAE) do
									if entity.level > level then
										castable = false
									end
								end
								if not castable then failsection = "target aoe level check" end
							end
							
							-- ALLY AE CHECK
							if ( castable and skill.tacount > 0 and skill.tarange > 0) then
								plistAE = EntityList("alive,myparty,maxdistance="..skill.tarange..",distanceto="..target.id)
								if (TableSize(plistAE) < skill.tacount) then castable = false end
								if not castable then failsection = "ally aoe check" end
							end
							
							-- ALLY HEALTH CHECK
							if ( castable and ValidTable(plistAE) and skill.tahpl > 0 ) then
								local count = 0
								for id, entity in pairs(plistAE) do
									if (entity.hp.current ~= 0 and (entity.hp.percent < skill.tahpl)) then
										count = count + 1
									end
								end
								
								if count < skill.tacount then castable = false end
								if not castable then failsection = "ally aoe health check" end
							end
							
							-- PREVIOUS SKILL
							if ( castable and SkillMgr.prevSkillID ~= "" and skill.pskill ~= "" ) then
								castable = false
								for i in skill.pskill:gmatch("%S+") do --custom
									--d("id:"..i..">"..SkillMgr.prevSkillID.."!!")
									if ( SkillMgr.prevSkillID == i and TimeSince(SkillMgr.prevFailedTimer) < 8000) then
										castable = true
										break
									end
								end
								if not castable then failsection = "previous skill" end
							end
							
							-- PREVIOUS SKILL NOT
							if ( castable and SkillMgr.prevSkillID ~= "" and skill.npskill ~= "" ) then
								for i in skill.npskill:gmatch("%S+") do --custom
									--d("id:"..i..">"..SkillMgr.prevSkillID.."!!")
									if ( SkillMgr.prevSkillID == i) then
										castable = false
										break
									end
								end
								if not castable then failsection = "previous skill not" end
							end
													
							-- ISMOVING CHECK
							if( castable) then
								if(Player:IsMoving() and realskilldata.casttime > 0 and not forceStop) then
									castable = false
								end
								if not castable then failsection = "is moving" end
							end
							
						end
					
					end
				end
			end
        end
    end
	
	if ( not castable ) then
		return failsection
	else
		return "succeeds"
	end
end

function SkillMgr.IsGCDReady()
	local castable = false
	local actionID = SkillMgr.teleCastSkills[Player.job]
	
	if (actionID) then
		local action = ActionList:Get(actionID)
		
		--d("Action cooldown is:"..(tostring(action.cd - action.cdmax)))
		if (action.cd - action.cdmax) <= .5	then
			castable = true
		end
	end
	
	return castable
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
			
		if (ml_global_information.AttackRange < 5 and
			gBotMode == strings[gCurrentLanguage].dutyMode and target.castinginfo.channelingid == 0 and
			gTeleport == "1" and not IsDutyLeader() and SkillMgr.teleCastTimer == 0 and SkillMgr.IsGCDReady()
			and target.targetid ~= Player.id) then
			ml_task_hub:CurrentTask().suppressFollow = true
			ml_task_hub:CurrentTask().suppressFollowTimer = Now() + 2500
			SkillMgr.teleBack = Player.pos
			Player:Stop()
			--GameHacks:TeleportToXYZ((pos.x+target.hitradius + 3), pos.y, pos.z)
			GameHacks:TeleportToXYZ(pos.x + 1, pos.y, pos.z)
			Player:SetTarget(ml_task_hub:CurrentTask().targetid)
			--Player:MoveToStraight(pos.x,pos.y,pos.z,1)
			SkillMgr.teleCastTimer = Now()
		end
		
		--if (TableSize(SkillMgr.teleBack) > 0 and (Distance2D(Player.pos.x,Player.pos.z,pos.x,pos.z) < 3)) then
			--Player:Stop()
		--end
		
		Player:SetFacingSynced(pos.x,pos.y,pos.z)
		SkillMgr.Cast( target )
		
		--if (SkillMgr.Cast( target )) then
			--SkillMgr.teleCastTimer = Now()
		--end
		
		if (TableSize(SkillMgr.teleBack) > 0 and (TimeSince(SkillMgr.teleCastTimer) >= 1200 or target.castinginfo.channelingid ~= 0)) then
			local back = SkillMgr.teleBack
			--Player:Stop()
			GameHacks:TeleportToXYZ(back.x, back.y, back.z)
			Player:SetFacingSynced(pos.x,pos.y,pos.z)
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
	
	if (not IsDutyLeader() and OnDutyMap() and not Quest:IsLoading() and Player.incombat and not ml_task_hub:CurrentTask().suppressFollow) then
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


--RegisterEventHandler("Gameloop.Update",SkillMgr.OnUpdate)
RegisterEventHandler("GUI.Item",SkillMgr.ButtonHandler)
RegisterEventHandler("SkillManager.toggle", SkillMgr.ToggleMenu)
RegisterEventHandler("GUI.Update",SkillMgr.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",SkillMgr.ModuleInit)

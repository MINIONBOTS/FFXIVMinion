-- Skillmanager for adv. skill customization
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
SkillMgr.UIRefreshPending = false
SkillMgr.UIRefreshTmr = 0
SkillMgr.StoopidEventAlreadyRegisteredList = {}
SkillMgr.prevSkillID = ""

function SkillMgr.ModuleInit() 	
	if (Settings.FFXIVMINION.gSMactive == nil) then
		Settings.FFXIVMINION.gSMactive = "0"
	end
	if (Settings.FFXIVMINION.gSMlastprofile == nil) then
		Settings.FFXIVMINION.gSMlastprofile = "None"
	end

	-- Skillbook
	GUI_NewWindow(SkillMgr.skillbook.name, SkillMgr.skillbook.x, SkillMgr.skillbook.y, SkillMgr.skillbook.w, SkillMgr.skillbook.h)
	GUI_NewButton(SkillMgr.skillbook.name,strings[gCurrentLanguage].skillbookrefresh,"SMRefreshSkillbookEvent")
	RegisterEventHandler("SMRefreshSkillbookEvent",SkillMgr.ButtonHandler)		
	GUI_UnFoldGroup(SkillMgr.skillbook.name,"AvailableSkills")
	GUI_SizeWindow(SkillMgr.skillbook.name,SkillMgr.skillbook.w,SkillMgr.skillbook.h)
	GUI_WindowVisible(SkillMgr.skillbook.name,false)	
	
	-- SelectedSkills/Main Window
	GUI_NewWindow(SkillMgr.mainwindow.name, SkillMgr.skillbook.x+SkillMgr.skillbook.w,SkillMgr.mainwindow.y,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
	GUI_NewCheckbox(SkillMgr.mainwindow.name,strings[gCurrentLanguage].activated,"gSMactive",strings[gCurrentLanguage].generalSettings)
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
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].maMarkerName,"SKM_NAME","SkillDetails")
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].maMarkerID,"SKM_ID","SkillDetails")
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].enabled,"SKM_ON","SkillDetails")
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].appliesBuff,"SKM_DOBUFF","SkillDetails")
	GUI_NewCheckbox(SkillMgr.editwindow.name,strings[gCurrentLanguage].useOutOfCombat,"SKM_OutOfCombat","SkillDetails")			
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].minRange,"SKM_MinR","SkillDetails")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].maxRange,"SKM_MaxR","SkillDetails")	
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerHPGT,"SKM_PHPL","SkillDetails")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerHPLT,"SKM_PHPB","SkillDetails")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerPowerGT ,"SKM_PPowL","SkillDetails")
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerPowerLT,"SKM_PPowB","SkillDetails")
	GUI_NewComboBox(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetType,"SKM_TRG","SkillDetails","Enemy,Player,Pet,Ally");
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetHPGT,"SKM_THPL","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetHPLT,"SKM_THPB","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].enemiesNearCount,"SKM_TECount","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].enemiesNearRange,"SKM_TERange","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].alliesNearCount,"SKM_TACount","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow.name,strings[gCurrentLanguage].alliesNearRange,"SKM_TARange","SkillDetails");
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerHas,"SKM_PBuff","SkillDetails");
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].playerHasNot,"SKM_PNBuff","SkillDetails");
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetHas,"SKM_TBuff","SkillDetails");
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].targetHasNot,"SKM_TNBuff","SkillDetails");
	GUI_NewField(SkillMgr.editwindow.name,strings[gCurrentLanguage].prevSkillID,"SKM_PSkillID","SkillDetails");		
	GUI_UnFoldGroup(SkillMgr.editwindow.name,"SkillDetails")

	GUI_WindowVisible(SkillMgr.editwindow.name,false)
	
	-- Crafting EDITOR WINDOW
	GUI_NewWindow(SkillMgr.editwindow_crafting.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow_crafting.w, SkillMgr.editwindow_crafting.h)		
	GUI_NewField(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].maMarkerName,"SKM_NAME","SkillDetails")
	GUI_NewField(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].maMarkerID,"SKM_ID","SkillDetails")
	GUI_NewCheckbox(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].enabled,"SKM_ON","SkillDetails")	
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].stepmin,"SKM_STMIN","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].stepmax,"SKM_STMAX","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].cpmin,"SKM_CPMIN","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].cpmax,"SKM_CPMAX","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].durabmin,"SKM_DURMIN","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].durabmax,"SKM_DURMAX","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].progrmin,"SKM_PROGMIN","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].progrmax,"SKM_PROGMAX","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].qualitymin,"SKM_QUALMIN","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].qualitymax,"SKM_QUALMAX","SkillDetails");
	GUI_NewComboBox(SkillMgr.editwindow_crafting.name,strings[gCurrentLanguage].condition,"SKM_CONDITION","SkillDetails"," ,Excellent,Good,Normal,Poor");
    
    -- Gathering EDITOR WINDOW
	GUI_NewWindow(SkillMgr.editwindow_gathering.name, SkillMgr.mainwindow.x+SkillMgr.mainwindow.w, SkillMgr.mainwindow.y, SkillMgr.editwindow_gathering.w, SkillMgr.editwindow_gathering.h)		
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].maMarkerName,"SKM_NAME","SkillDetails")
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].maMarkerID,"SKM_ID","SkillDetails")
	GUI_NewCheckbox(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].enabled,"SKM_ON","SkillDetails")	
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].gpmin,"SKM_GPMIN","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].gpmax,"SKM_GPMAX","SkillDetails");
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].playerHas,"SKM_PBuff","SkillDetails");
	GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].playerHasNot,"SKM_PNBuff","SkillDetails");
	GUI_NewNumeric(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].gatherAttempts,"SKM_GAttempts","SkillDetails");
    GUI_NewField(SkillMgr.editwindow_gathering.name,strings[gCurrentLanguage].nodeHas,"SKM_ITEM","SkillDetails");
	
	GUI_UnFoldGroup(SkillMgr.editwindow_crafting.name,"SkillDetails")
	GUI_NewButton(SkillMgr.editwindow_crafting.name,"DELETE","SMEDeleteEvent")
	RegisterEventHandler("SMEDeleteEvent",SkillMgr.ButtonHandler)	
	GUI_NewButton(SkillMgr.editwindow_crafting.name,"DOWN","SMESkillDOWNEvent")	
	RegisterEventHandler("SMESkillDOWNEvent",SkillMgr.ButtonHandler)	
	GUI_NewButton(SkillMgr.editwindow_crafting.name,"UP","SMESkillUPEvent")
	RegisterEventHandler("SMESkillUPEvent",SkillMgr.ButtonHandler)
	GUI_SizeWindow(SkillMgr.editwindow_crafting.name,SkillMgr.editwindow_crafting.w,SkillMgr.editwindow_crafting.h)
	GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)
	
	GUI_UnFoldGroup(SkillMgr.editwindow_gathering.name,"SkillDetails")
	GUI_NewButton(SkillMgr.editwindow_gathering.name,"DELETE","SMEDeleteEvent")
	GUI_NewButton(SkillMgr.editwindow_gathering.name,"DOWN","SMESkillDOWNEvent")		
	GUI_NewButton(SkillMgr.editwindow_gathering.name,"UP","SMESkillUPEvent")
	GUI_SizeWindow(SkillMgr.editwindow_gathering.name,SkillMgr.editwindow_gathering.w,SkillMgr.editwindow_gathering.h)
	GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)
	
	GUI_UnFoldGroup(SkillMgr.editwindow.name,"SkillDetails")
	GUI_NewButton(SkillMgr.editwindow.name,"DELETE","SMEDeleteEvent")
	GUI_NewButton(SkillMgr.editwindow.name,"DOWN","SMESkillDOWNEvent")	
	GUI_NewButton(SkillMgr.editwindow.name,"UP","SMESkillUPEvent")
	GUI_SizeWindow(SkillMgr.editwindow.name,SkillMgr.editwindow.w,SkillMgr.editwindow.h)
	GUI_WindowVisible(SkillMgr.editwindow.name,false)
	
	SKM_NAME = ""
	SKM_ID = 0
	SKM_ON = "0"
	SKM_DOBUFF = "0"
	SKM_Prio = 0
	SKM_OutOfCombat = "0"
	SKM_TRG = "Enemy"
	SKM_MinR = 0
	SKM_MaxR = 0	
	SKM_PHPL = 0
	SKM_PHPB = 0
	SKM_PPowL = 0
	SKM_PPowB = 0
	SKM_THPL = 0
	SKM_THPB = 0
	SKM_TECount = 0
	SKM_TERange = 0
	SKM_TACount = 0
	SKM_TARange = 0
	SKM_PBuff = ""
	SKM_PNBuff = ""
	SKM_TBuff = ""
	SKM_TNBuff = ""
	SKM_PSkillID = 0
	--Crafting
	SKM_STMIN = 0
	SKM_STMAX = 0
	SKM_CPMIN = 0
	SKM_CPMAX = 0
	SKM_DURMIN = 0
	SKM_DURMAX = 0
	SKM_PROGMIN = 0
	SKM_PROGMAX = 0
	SKM_QUALMIN = 0
	SKM_QUALMAX = 0
	SKM_CONDITION = " "
	--Gathering
	SKM_GPMIN = 0
	SKM_GPMAX = 0
    SKM_Item  = ""
	SKM_GAttempts = 0

	SkillMgr.SkillBook = {}
	SkillMgr.SkillProfile = {}
	SkillMgr.UpdateProfiles()
	
	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
	
	SkillMgr.UpdateCurrentProfileData()
	GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
end

function SkillMgr.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		--d(tostring(k).." = "..tostring(v))
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
		elseif ( k == "SKM_NAME" ) then SkillMgr.SkillProfile[SKM_Prio].name = v		
		elseif ( k == "SKM_ON" ) then SkillMgr.SkillProfile[SKM_Prio].used = v
		elseif ( k == "SKM_DOBUFF" ) then SkillMgr.SkillProfile[SKM_Prio].dobuff = v
		elseif ( k == "SKM_TRG" ) then SkillMgr.SkillProfile[SKM_Prio].trg = v
		elseif ( k == "SKM_OutOfCombat" ) then SkillMgr.SkillProfile[SKM_Prio].ooc = v
		elseif ( k == "SKM_MinR" ) then SkillMgr.SkillProfile[SKM_Prio].minRange = tonumber(v)
		elseif ( k == "SKM_MaxR" ) then SkillMgr.SkillProfile[SKM_Prio].maxRange = tonumber(v)		
		elseif ( k == "SKM_PHPL" ) then SkillMgr.SkillProfile[SKM_Prio].phpl = tonumber(v)
		elseif ( k == "SKM_PHPB" ) then SkillMgr.SkillProfile[SKM_Prio].phpb = tonumber(v)
		elseif ( k == "SKM_PPowL" ) then SkillMgr.SkillProfile[SKM_Prio].ppowl = tonumber(v)
		elseif ( k == "SKM_PPowB" ) then SkillMgr.SkillProfile[SKM_Prio].ppowb = tonumber(v)	
		elseif ( k == "SKM_THPL" ) then SkillMgr.SkillProfile[SKM_Prio].thpl = tonumber(v)
		elseif ( k == "SKM_THPB" ) then SkillMgr.SkillProfile[SKM_Prio].thpb = tonumber(v)
		elseif ( k == "SKM_TECount" ) then SkillMgr.SkillProfile[SKM_Prio].tecount = tonumber(v)
		elseif ( k == "SKM_TERange" ) then SkillMgr.SkillProfile[SKM_Prio].terange = tonumber(v)
		elseif ( k == "SKM_TACount" ) then SkillMgr.SkillProfile[SKM_Prio].tacount = tonumber(v)
		elseif ( k == "SKM_TARange" ) then SkillMgr.SkillProfile[SKM_Prio].terange = tonumber(v)
		elseif ( k == "SKM_PBuff" ) then SkillMgr.SkillProfile[SKM_Prio].pbuff = v
		elseif ( k == "SKM_PNBuff" ) then SkillMgr.SkillProfile[SKM_Prio].pnbuff = v
		elseif ( k == "SKM_TBuff" ) then SkillMgr.SkillProfile[SKM_Prio].tbuff = v
		elseif ( k == "SKM_TNBuff" ) then SkillMgr.SkillProfile[SKM_Prio].tnbuff = v
		elseif ( k == "SKM_PSkillID" ) then SkillMgr.SkillProfile[SKM_Prio].pskill = v
		--crafting
		elseif ( k == "SKM_STMIN" ) then SkillMgr.SkillProfile[SKM_Prio].stepmin = tonumber(v)
		elseif ( k == "SKM_STMAX" ) then SkillMgr.SkillProfile[SKM_Prio].stepmax = tonumber(v)
		elseif ( k == "SKM_CPMIN" ) then SkillMgr.SkillProfile[SKM_Prio].cpmin = tonumber(v)
		elseif ( k == "SKM_CPMAX" ) then SkillMgr.SkillProfile[SKM_Prio].cpmax = tonumber(v)
		elseif ( k == "SKM_DURMIN" ) then SkillMgr.SkillProfile[SKM_Prio].durabmin = tonumber(v)
		elseif ( k == "SKM_DURMAX" ) then SkillMgr.SkillProfile[SKM_Prio].durabmax = tonumber(v)
		elseif ( k == "SKM_PROGMIN" ) then SkillMgr.SkillProfile[SKM_Prio].progrmin = tonumber(v)
		elseif ( k == "SKM_PROGMAX" ) then SkillMgr.SkillProfile[SKM_Prio].progrmax = tonumber(v)
		elseif ( k == "SKM_QUALMIN" ) then SkillMgr.SkillProfile[SKM_Prio].qualitymin = tonumber(v)
		elseif ( k == "SKM_QUALMAX" ) then SkillMgr.SkillProfile[SKM_Prio].qualitymax = tonumber(v)
		elseif ( k == "SKM_CONDITION" ) then SkillMgr.SkillProfile[SKM_Prio].condition = v
        --gathering
		elseif ( k == "SKM_GPMIN" ) then SkillMgr.SkillProfile[SKM_Prio].gpmin = tonumber(v)
		elseif ( k == "SKM_GPMAX" ) then SkillMgr.SkillProfile[SKM_Prio].gpmax = tonumber(v)
		elseif ( k == "SKM_GAttempts" ) then SkillMgr.SkillProfile[SKM_Prio].gatherattempts = tonumber(v)
		elseif ( k == "SKM_ITEM" ) then SkillMgr.SkillProfile[SKM_Prio].hasitem = v
		end
	end
end


function SkillMgr.OnUpdate( event, tick )
	
	if ( gSMactive == "1" ) then		
		if	( tick - SkillMgr.lasttick > 150 ) then
			SkillMgr.lasttick = tick
			
		end
	end
	
	-- Needed because the UI cant handle clearing + rebuilding of all stuff in the same frame
	if ( SkillMgr.UIRefreshPending ) then			
		if ( SkillMgr.UIRefreshTmr == 0 ) then		
			SkillMgr.UIRefreshTmr = tick			
		elseif( tick - SkillMgr.UIRefreshTmr > 250 ) then		
			SkillMgr.UIRefreshTmr = 0			
			SkillMgr.RefreshSkillList()	
			SkillMgr.UIRefreshPending = false			
		end
	end
end

--+
function SkillMgr.ButtonHandler(event)
	gSMRecactive = "0"
	if ( event == "SMDeleteEvent" ) then
		-- Delete the currently selected Profile - file from the HDD
		if (gSMprofile ~= nil and gSMprofile ~= "None" and gSMprofile ~= "") then
			d("Deleting current Profile: "..gSMprofile)
			os.remove(SkillMgr.profilepath ..gSMprofile..".lua")	
			SkillMgr.UpdateProfiles()	
		end
		
	elseif ( event == "SMRefreshSkillbookEvent") then
		SkillMgr.SkillBook = {}
		GUI_DeleteGroup(SkillMgr.skillbook.name,"AvailableSkills")		
		SkillMgr.RefreshSkillBook()		
		
	elseif ( event == "SMEDeleteEvent") then				
		if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
			GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
			local i,s = next ( SkillMgr.SkillProfile, SKM_Prio)
			while i and s do
				s.prio = s.prio - 1
				SkillMgr.SkillProfile[SKM_Prio] = s
				SKM_Prio = i
				i,s = next ( SkillMgr.SkillProfile, i)
			end
			SkillMgr.SkillProfile[SKM_Prio] = nil
			SkillMgr.RefreshSkillList()	
			GUI_WindowVisible(SkillMgr.editwindow.name,false)
			GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)			
		end
		
	elseif (event == "SMESkillUPEvent") then		
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
		
	elseif ( event == "SMESkillDOWNEvent") then			
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
end

function SkillMgr.CreateNewProfile()
	
	-- Delete existing Skills
	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
	gSMprofile = "None"
	Settings.FFXIVMINION.gSMlastprofile = gSMprofile
	gSMnewname = ""	
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
			--d("X: "..tostring(profile).." == "..tostring(gSMnewname))
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
	gSMprofile = found
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
		local skID,skill = next (SkillMgr.SkillProfile)
		local job = Player.job
		while skID and skill do
			string2write = string2write.."SKM_NAME="..skill.name.."\n"
			string2write = string2write.."SKM_ID="..skill.id.."\n"
			string2write = string2write.."SKM_ON="..skill.used.."\n"
			string2write = string2write.."SKM_Prio="..skill.prio.."\n"
			if ( job >= 8 and job <=15 ) then
				--crafting
				string2write = string2write.."SKM_STMIN="..skill.stepmin.."\n"			
				string2write = string2write.."SKM_STMAX="..skill.stepmax.."\n"			
				string2write = string2write.."SKM_CPMIN="..skill.cpmin.."\n"			
				string2write = string2write.."SKM_CPMAX="..skill.cpmax.."\n"			
				string2write = string2write.."SKM_DURMIN="..skill.durabmin.."\n"			
				string2write = string2write.."SKM_DURMAX="..skill.durabmax.."\n"			
				string2write = string2write.."SKM_PROGMIN="..skill.progrmin.."\n"			
				string2write = string2write.."SKM_PROGMAX="..skill.progrmax.."\n"			
				string2write = string2write.."SKM_QUALMIN="..skill.qualitymin.."\n"		
				string2write = string2write.."SKM_QUALMAX="..skill.qualitymax.."\n"			
				string2write = string2write.."SKM_CONDITION="..skill.condition.."\n"				
            elseif ( job >= 16 and job <=17 ) then
				-- gathering		
				string2write = string2write.."SKM_GPMIN="..skill.gpmin.."\n"			
				string2write = string2write.."SKM_GPMAX="..skill.gpmax.."\n"
				string2write = string2write.."SKM_PBuff="..skill.pbuff.."\n" 
				string2write = string2write.."SKM_PNBuff="..skill.pnbuff.."\n"
				string2write = string2write.."SKM_GAttempts="..skill.gatherattempts.."\n"   				
				string2write = string2write.."SKM_ITEM="..skill.hasitem.."\n"          
			else
				string2write = string2write.."SKM_DOBUFF="..skill.dobuff.."\n"			
				string2write = string2write.."SKM_TRG="..skill.trg.."\n"		
				string2write = string2write.."SKM_OutOfCombat="..skill.ooc.."\n"			
				string2write = string2write.."SKM_MinR="..skill.minRange.."\n"
				string2write = string2write.."SKM_MaxR="..skill.maxRange.."\n" 			
				string2write = string2write.."SKM_PHPL="..skill.phpl.."\n" 
				string2write = string2write.."SKM_PHPB="..skill.phpb.."\n" 
				string2write = string2write.."SKM_PPowL="..skill.ppowl.."\n" 
				string2write = string2write.."SKM_PPowB="..skill.ppowb.."\n" 
				string2write = string2write.."SKM_THPL="..skill.thpl.."\n" 
				string2write = string2write.."SKM_THPB="..skill.thpb.."\n" 
				string2write = string2write.."SKM_TECount="..skill.tecount.."\n" 
				string2write = string2write.."SKM_TERange="..skill.terange.."\n" 
				string2write = string2write.."SKM_TACount="..skill.tacount.."\n" 
				string2write = string2write.."SKM_TARange="..skill.terange.."\n"
				string2write = string2write.."SKM_PBuff="..skill.pbuff.."\n" 
				string2write = string2write.."SKM_PNBuff="..skill.pnbuff.."\n" 			
				string2write = string2write.."SKM_TBuff="..skill.tbuff.."\n" 
				string2write = string2write.."SKM_TNBuff="..skill.tnbuff.."\n"
				string2write = string2write.."SKM_PSkillID="..skill.pskill.."\n" 
			end
						
			string2write = string2write.."SKM_END=0\n"
		
			skID,skill = next (SkillMgr.SkillProfile,skID)
		end	
		d(filewrite(SkillMgr.profilepath ..filename..".lua",string2write))
		
		if ( isnew ) then
			gSMprofile_listitems = gSMprofile_listitems..","..filename
			gSMprofile = filename
			Settings.FFXIVMINION.gSMlastprofile = filename
		end
	end
end

--+
function SkillMgr.UpdateCurrentProfileData()
	if ( gSMprofile ~= nil and gSMprofile ~= "" and gSMprofile ~= "None" ) then
		local profile = fileread(SkillMgr.profilepath..gSMprofile..".lua")
		if ( TableSize(profile) > 0) then
			local unsortedSkillList = {}			
			local newskill = {}	
			local i, line = next (profile)
			
			if ( line ) then
				local version
				-- Check for backwards compatib
				local _, key, id, value = string.match(line, "(%w+)_(%w+)_(%d+)=(.*)")
				if ( tostring(key) == "SMVersion" and tostring(id) == "1") then
					version = 1
				end
				while i and line do
					local key, value
					if ( version == 1 ) then 
						_, key, value = string.match(line, "(%w+)_(%w+)=(.*)")
					end					
					--d("key: "..tostring(key).." value:"..tostring(value))
					
					if ( key and value ) then
						value = string.gsub(value, "\r", "")					
						if ( key == "END" ) then
							--d("Adding Skill :"..newskill.name.."Prio:"..tostring(newskill.prio))
							table.insert(unsortedSkillList,tonumber(newskill.prio),newskill)						
							newskill = {}
							elseif ( key == "ID" )then newskill.id = tonumber(value)
							elseif ( key == "NAME" )then newskill.name = value
							elseif ( key == "ON" )then newskill.used = tostring(value)
							elseif ( key == "DOBUFF" )then newskill.dobuff = tostring(value)							
							elseif ( key == "Prio" )then newskill.prio = tonumber(value)
							elseif ( key == "OutOfCombat" )then newskill.ooc = tostring(value)
							elseif ( key == "TRG" )then newskill.trg = tostring(value)							
							elseif ( key == "MinR" )then newskill.minRange = tonumber(value)
							elseif ( key == "MaxR" )then newskill.maxRange = tonumber(value) 							
							elseif ( key == "PHPL" )then newskill.phpl = tonumber(value)
							elseif ( key == "PHPB" )then newskill.phpb = tonumber(value)
							elseif ( key == "PPowL" )then newskill.ppowl = tonumber(value)
							elseif ( key == "PPowB" )then newskill.ppowb = tonumber(value)
							elseif ( key == "THPL" )then newskill.thpl = tonumber(value)
							elseif ( key == "THPB" )then newskill.thpb = tonumber(value)						
							elseif ( key == "TECount" )then newskill.tecount = tonumber(value)
							elseif ( key == "TERange" )then newskill.terange = tonumber(value)
							elseif ( key == "TACount" )then newskill.tacount = tonumber(value)
							elseif ( key == "TARange" )then newskill.tarange = tonumber(value)
							elseif ( key == "PBuff" )then newskill.pbuff = tostring(value)
							elseif ( key == "PNBuff" )then newskill.pnbuff = tostring(value)
							elseif ( key == "TBuff" )then newskill.tbuff = tostring(value)
							elseif ( key == "TNBuff" )then newskill.tnbuff = tostring(value)
							elseif ( key == "PSkillID" ) then newskill.pskill = tostring(value)
							--crafting
							elseif ( key == "STMIN" ) then newskill.stepmin = tonumber(value)
							elseif ( key == "STMAX" ) then newskill.stepmax = tonumber(value)
							elseif ( key == "CPMIN" ) then newskill.cpmin = tonumber(value)
							elseif ( key == "CPMAX" ) then newskill.cpmax = tonumber(value)
							elseif ( key == "DURMIN" ) then newskill.durabmin = tonumber(value)
							elseif ( key == "DURMAX" ) then newskill.durabmax = tonumber(value)
							elseif ( key == "PROGMIN" ) then newskill.progrmin = tonumber(value)
							elseif ( key == "PROGMAX" ) then newskill.progrmax = tonumber(value)
							elseif ( key == "QUALMIN" ) then newskill.qualitymin = tonumber(value)
							elseif ( key == "QUALMAX" ) then newskill.qualitymax = tonumber(value)
							elseif ( key == "CONDITION" ) then newskill.condition = tostring(value)
                            --gathering
							elseif ( key == "GPMIN" ) then newskill.gpmin = tonumber(value)
							elseif ( key == "GPMAX" ) then newskill.gpmax = tonumber(value)
							elseif ( key == "GAttempts" ) then newskill.gatherattempts = tonumber(value)
							elseif ( key == "ITEM" ) then newskill.hasitem = tostring(value)
							
						end
					else
						d("Error loading inputline: Key: "..(tostring(key)).." value:"..tostring(value))
					end				
					i, line = next (profile,i)
				end
			end
			
			-- Create UI Fields
			local sortedSkillList = {}
			if ( TableSize(unsortedSkillList) > 0 ) then
				local i,skill = next (unsortedSkillList)
				while i and skill do
					sortedSkillList[#sortedSkillList+1] = skill
					i,skill = next (unsortedSkillList,i)
				end
				table.sort(sortedSkillList, function(a,b) return a.prio < b.prio end )	
				for i = 1,TableSize(sortedSkillList),1 do					
					if (sortedSkillList[i] ~= nil ) then
						sortedSkillList[i].prio = i						
						SkillMgr.CreateNewSkillEntry(sortedSkillList[i])
					end
				end
			end
		else
			d("Profile is empty..")
		end		
	else
		d("No new SkillProfile selected!")		
	end
	GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
end


--+Rebuilds the UI Entries for the SkillbookList
function SkillMgr.RefreshSkillBook()
	local SkillList = ActionList("type=1,minlevel=1")
	
	if ( TableSize( SkillList ) > 0 ) then
		local i,s = next ( SkillList )
		while i and s and s.id do
			SkillMgr.CreateNewSkillBookEntry(s)
			i,s = next ( SkillList , i )
		end
	end
	
	--craftingskills
	local job = Player.job
	if ( job >= 8 and job <=15 ) then
		SkillList = ActionList("type=9")
		if ( TableSize( SkillList ) > 0 ) then
			local i,s = next ( SkillList )
			while i and s and s.id do
				SkillMgr.CreateNewSkillBookEntry(s)
				i,s = next ( SkillList , i )
			end
		end
	end

	GUI_UnFoldGroup(SkillMgr.skillbook.name,"AvailableSkills")
end
--+
function SkillMgr.CreateNewSkillBookEntry(skill)	
	if (skill ~= nil ) then
		local skname = skill.name
		local skID = skill.id	
		if (skname and skname ~= "" and skID ) then			
			local newskillprio = skill.prio or table.maxn(SkillMgr.SkillBook)+1
			
			GUI_NewButton(SkillMgr.skillbook.name, skname, skname,"AvailableSkills")
			
			if ( SkillMgr.StoopidEventAlreadyRegisteredList[skname] == nil ) then
				RegisterEventHandler(skname,SkillMgr.AddSkillToProfile)
				SkillMgr.StoopidEventAlreadyRegisteredList[skname] = 1
			end	
			
			SkillMgr.SkillBook[skname] = skill
		end		
	end
end
-- Button Handler for Skillbook-skill-buttons
function SkillMgr.AddSkillToProfile(event)
	if (SkillMgr.SkillBook[event]) then
		SkillMgr.CreateNewSkillEntry(SkillMgr.SkillBook[event])
	end
end


--+Rebuilds the UI Entries for the Profile-SkillList
function SkillMgr.RefreshSkillList()	
	if ( TableSize( SkillMgr.SkillProfile ) > 0 ) then
		local i,s = next ( SkillMgr.SkillProfile )
		while i and s do
			SkillMgr.CreateNewSkillEntry(s)
			i,s = next ( SkillMgr.SkillProfile , i )
		end
	end
	GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
end
--+
function SkillMgr.CreateNewSkillEntry(skill)	
	if (skill ~= nil ) then
		local skname = skill.name
		local skID = skill.id
		
		if (skname ~= "" and skID ) then
			local newskillprio = skill.prio or table.maxn(SkillMgr.SkillProfile)+1
			local bevent = tostring(newskillprio)
			GUI_NewButton(SkillMgr.mainwindow.name, tostring(bevent)..": "..skname, bevent,"ProfileSkills")
			
			if ( SkillMgr.StoopidEventAlreadyRegisteredList[newskillprio] == nil ) then
				RegisterEventHandler(bevent,SkillMgr.EditSkill)
				SkillMgr.StoopidEventAlreadyRegisteredList[newskillprio] = 1
			end	
			
			SkillMgr.SkillProfile[newskillprio] = {		
				id = skID,
				prio = newskillprio,
				name = skname or "",
				used = skill.used or "1",
				dobuff = skill.dobuff or "0",
				ooc = skill.ooc or "0",
				trg = skill.trg or "Enemy",
				minRange = skill.minRange or 0,
				maxRange = skill.maxRange or skill.range or 0,				
				phpl = skill.phpl or 0,
				phpb = skill.phpb or 0,
				ppowl = skill.ppowl or 0,
				ppowb = skill.ppowb or 0,
				thpl = skill.thpl or 0,
				thpb = skill.thpb or 0,
				tecount = skill.tecount or 0,
				terange = skill.terange or 0,
				tacount = skill.tacount or 0,
				tarange = skill.tarange or 0,
				pbuff = skill.pbuff or "",
				pnbuff = skill.pnbuff or "",
				tbuff = skill.tbuff or "",
				tnbuff = skill.tnbuff or "",
				pskill = skill.pskill or "",
				--crafting
				stepmin = skill.stepmin or 0,
				stepmax = skill.stepmax or 0,
				cpmin = skill.cpmin or 0,
				cpmax = skill.cpmax or 0,
				durabmin = skill.durabmin or 0,
				durabmax = skill.durabmax or 0,
				progrmin = skill.progrmin or 0,
				progrmax = skill.progrmax or 0,
				qualitymin = skill.qualitymin or 0,
				qualitymax = skill.qualitymax or 0,
				condition = skill.condition or "",
				--gathering
				gpmin=skill.gpmin or 0,
				gpmax=skill.gpmax or 0,
				gatherattempts=skill.gatherattempts or 0,
				hasitem =skill.hasitem or ""
			}	
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
			SKM_NAME = skill.name or ""
			SKM_ID = skill.id
			SKM_ON = skill.used or "1"
			SKM_Prio = tonumber(event)	
			SKM_STMIN = tonumber(skill.stepmin) or 0
			SKM_STMAX = tonumber(skill.stepmax) or 0
			SKM_CPMIN = tonumber(skill.cpmin) or 0
			SKM_CPMAX = tonumber(skill.cpmax) or 0
			SKM_DURMIN = tonumber(skill.durabmin) or 0
			SKM_DURMAX = tonumber(skill.durabmax) or 0
			SKM_PROGMIN = tonumber(skill.progrmin) or 0
			SKM_PROGMAX = tonumber(skill.progrmax) or 0
			SKM_QUALMIN = tonumber(skill.qualitymin) or 0
			SKM_QUALMAX = tonumber(skill.qualitymax) or 0
			SKM_CONDITION = skill.condition or "Normal"
		
		end	
    elseif ( job >= 16 and job <=17 ) then
		-- Gathering Editor 
		GUI_MoveWindow( SkillMgr.editwindow_gathering.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(SkillMgr.editwindow_gathering.name,true)
		-- Update EditorData
		local skill = SkillMgr.SkillProfile[tonumber(event)]	
		if ( skill ) then		
			SKM_NAME = skill.name or ""
			SKM_ID = skill.id
			SKM_ON = skill.used or "1"
			SKM_Prio = tonumber(event)	
			SKM_GPMIN = tonumber(skill.gpmin) or 0
			SKM_GPMAX = tonumber(skill.gpmax) or 0
			SKM_PBuff = skill.pbuff or ""
			SKM_PNBuff = skill.pnbuff or ""
			SKM_GAttempts = tonumber(skill.gatherattempts) or 0
			SKM_ITEM = skill.hasitem or ""
		end	
	else	
		-- Normal Editor 
		GUI_MoveWindow( SkillMgr.editwindow.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(SkillMgr.editwindow.name,true)
		-- Update EditorData
		local skill = SkillMgr.SkillProfile[tonumber(event)]	
		if ( skill ) then		
			SKM_NAME = skill.name or ""
			SKM_ID = skill.id
			SKM_ON = skill.used or "1"
			SKM_DOBUFF = skill.dobuff or "0"
			SKM_Prio = tonumber(event)
			SKM_OutOfCombat = skill.ooc or "0"
			SKM_TRG = skill.trg or "Enemy"
			SKM_MinR = tonumber(skill.minRange) or 0
			SKM_MaxR = tonumber(skill.maxRange) or 3		
			SKM_PHPL = tonumber(skill.phpl) or 0
			SKM_PHPB = tonumber(skill.phpb) or 0
			SKM_PPowL = tonumber(skill.ppowl) or 0
			SKM_PPowB = tonumber(skill.ppowb) or 0
			SKM_THPL = tonumber(skill.thpl) or 0
			SKM_THPB = tonumber(skill.thpb) or 0
			SKM_TECount = tonumber(skill.tecount) or 0
			SKM_TERange = tonumber(skill.terange) or 0
			SKM_TACount = tonumber(skill.tacount) or 0
			SKM_TARange = tonumber(skill.terange) or 0
			SKM_PBuff = skill.pbuff or ""
			SKM_PNBuff = skill.pnbuff or ""
			SKM_TBuff = skill.tbuff or ""
			SKM_TNBuff = skill.tnbuff or ""
			SKM_PSkillID = skill.pskill or ""
		end
	end
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
			--d(tostring(skill.trg).." "..tostring(skill.thpb))
			if ( (skill.trg == "Ally" or skill.trg == "Player") and skill.thpb > 0 and skill.thpb > highestHPLimit ) then
				highestHPLimit = skill.thpb
			end
		end
	end
	return highestHPLimit
end

function SkillMgr.Cast( entity )
	if ( entity ) then
		local PID = Player.id
		local pbuffs = Player.buffs
		
		local EID = entity.id				
		local ebuffs = entity.buffs
		
		local pet = Player.pet
		
		local ally = GetBestHealTarget()
		
		if ( EID and PID and TableSize(SkillMgr.SkillProfile) > 0 and not ActionList:IsCasting()) then
			
			for prio,skill in pairs(SkillMgr.SkillProfile) do
				if ( skill.used == "1" ) then		-- takes care of los, range, facing target and valid target		
					local realskilldata = ActionList:Get(skill.id)
					if ( realskilldata and realskilldata.isready ) then 
						
						--reset our variables
						target = entity
						TID = EID
						tbuffs = ebuffs
						
						local castable = true
						--COOLDOWN
						--d(realskilldata.cd)
						--if (realskilldata.cd ~= 0 and math.abs(realskilldata.cd-2.5) < .00001) then castable = false end  --2.5 is a dummyfix, game is bugged 
						--d(castable)
						
						-- soft cooldown for compensating the delay between spell cast and buff applies on target)
						if ( skill.dobuff and skill.lastcast ~= nil and ml_global_information.Now - skill.lastcast < (realskilldata.casttime*1000 + 500)) then castable = false end
						
						-- PLAYER HEALTH, TP/MP
						if ( castable and (
							(skill.phpl > 0 and skill.phpl > Player.hp.percent)
							or (skill.phpb > 0 and skill.phpb < Player.hp.percent)
							or (skill.ppowl > 0 and skill.ppowl > Player.mp.current)
							or (skill.ppowb > 0 and skill.ppowb < Player.mp.current)					
							)) then castable = false end	
						
						-- PLAYER BUFFS
						if ( castable and TableSize(pbuffs) > 0) then 							
							-- dont cast this spell when we have not at least one of the BuffIDs in the skill.pbuff list
							if (skill.pbuff ~= "" ) then								
								local tbfound = false
								for buffid in StringSplit(skill.pbuff,",") do
									if (tonumber(buffid) ~= nil) then
										for i, buff in pairs(pbuffs) do
											if (buff.id == tonumber(buffid)) then--and buff.ownerid == PID) then
												tbfound = true
												break
											end
										end	
									end
								end
								if not tbfound then castable = false end								
							end
							-- dont cast this spell when we have any of the BuffIDs in the skill.pnbuff list
							if (skill.pnbuff ~= "" ) then
								local tbfound = false
								for buffid in StringSplit(skill.pnbuff,",") do
									if (tonumber(buffid) ~= nil) then
										for i, buff in pairs(pbuffs) do
											if (buff.id == tonumber(buffid)) then --and buff.ownerid == PID) then
												tbfound = true
												break
											end
										end	
									end
								end
								if tbfound then castable = false end								
							end							
						end	
						
																															
						-- SWITCH TARGET FOR PET / ALLY - CHECK
						if ( skill.trg == "Pet" ) then
							if ( pet ~= nil and pet ~= 0) then
								if ( SkillMgr.IsPetSummonSkill(skill.id) ) then castable = false end -- we still have a pet, no need to summon
								target = pet
								TID = pet.id
								tbuffs = pet.buffs
								
							else	
							
							-- we have no pet, check if the skill is summoning a new pet, else dont cast
								if not SkillMgr.IsPetSummonSkill(skill.id) then 
									castable = false 
								else
									-- we need to cast the summon on our player
									target = Player
									TID = PID
									tbuffs = pbuffs
								end
							end
						elseif ( skill.trg == "Ally" ) then
							if ( ally ~= nil and ally.id ~= PID) then
								target = ally
								TID = ally.id
								tbuffs = ally.buffs
							end
						elseif ( skill.trg == "Player" ) then							
							target = Player
							TID = PID
							tbuffs = pbuffs
						end
						-- RANGE 							
						if ( castable and (
								   (skill.minRange > 0 and target.distance < skill.minRange)
								or (skill.maxRange > 0 and target.distance > skill.maxRange+target.hitradius+1)--target.distance- target.hitradius > skill.maxRange)
								)) then castable = false end
												
						-- HEALTH
						if ( castable and (
							(skill.thpl > 0 and skill.thpl > target.hp.percent)
							or (skill.thpb > 0 and skill.thpb < target.hp.percent)
							)) then castable = false end									
						
						
						-- TARGET BUFFS
						if ( castable and TableSize(tbuffs) > 0) then 							
							-- dont cast this spell when the target has not at least one of the BuffIDs in the skill.tbuff list
							if (skill.tbuff ~= "" ) then								
								local tbfound = false
								for buffid in StringSplit(skill.tbuff,",") do
									if (tonumber(buffid) ~= nil) then
										for i, buff in pairs(tbuffs) do
											if (buff.id == tonumber(buffid) and buff.ownerid == PID) then
												tbfound = true
												break
											end
										end	
									end
								end
								if not tbfound then castable = false end								
							end
							-- dont cast this spell when the target has any of the BuffIDs in the skill.tnbuff list
							if (skill.tnbuff ~= "" ) then
								local tbfound = false
								for buffid in StringSplit(skill.tnbuff,",") do
									if (tonumber(buffid) ~= nil) then
										for i, buff in pairs(tbuffs) do
											if (buff.id == tonumber(buffid) and buff.ownerid == PID) then
												tbfound = true
												break
											end
										end	
									end
								end
								if tbfound then castable = false end								
							end							
						end
									
						
						-- TARGET AE CHECK
						if ( castable and skill.tecount > 0 and skill.terange > 0) then
							if ( ( TableSize(EntityList("alive,attackable,maxdistance="..skill.terange..",distanceto="..target.id)) < skill.tecount)) then
								castable = false
							end
						end
						
						-- PREVIOUS SKILL
						if ( castable and SkillMgr.prevSkillID ~= "" and skill.pskill ~= "" ) then
							if ( SkillMgr.prevSkillID ~= skill.pskill) then
								castable = false
							end
						end
						if ( castable ) then
							-- Noob check for making sure we cast the spell on the correct target (buffs n heals only on us/friends, attacks enemies)
							if ( ActionList:CanCast(skill.id,tonumber(TID) )) then -- takes care of los, range, facing target and valid target								
								d("CASTING : "..tostring(skill.name) .." on "..tostring(target.name))								
								if ( ActionList:Cast(skill.id,TID) ) then									
									skill.lastcast = ml_global_information.Now
									SkillMgr.prevSkillID = tostring(skill.id)
								end
							--[[elseif ( ActionList:CanCast(skill.id,tonumber(PID) )) then
								d("CASTING(heal/buff) : "..tostring(skill.name) .." on "..tostring(target.name))
								if ( ActionList:Cast(skill.id,PID) ) then									
									skill.lastcast = ml_global_information.Now
									SkillMgr.prevSkillID = tostring(skill.id)
								end	]]							
							end
						end
					end					
				end
			end
		end
	end
end

function SkillMgr.Craft( )
	
	local synth = Crafting:SynthInfo()
	if ( TableSize(synth) > 0 and TableSize(SkillMgr.SkillProfile) > 0 and not ActionList:IsCasting()) then
		
		for prio,skill in pairs(SkillMgr.SkillProfile) do
			if ( skill.used == "1" ) then		-- takes care of los, range, facing target and valid target		
				
				local realskilldata = ActionList:Get(skill.id)
				if ( realskilldata and realskilldata.isready ) then
					if ( realskilldata.isready ) then
						local castable = true
						local pbuffs = Player.buffs
						
						if ( (skill.stepmin > 0 and synth.step < skill.stepmin) or
							 (skill.stepmax > 0 and synth.step > skill.stepmax) or
							 (skill.cpmin > 0 and Player.cp.current < skill.cpmin) or
							 (skill.cpmax > 0 and Player.cp.current > skill.cpmax) or
							 (skill.durabmin > 0 and synth.durability < skill.durabmin) or
							 (skill.durabmax > 0 and synth.durability > skill.durabmax) or
							 (skill.progrmin > 0 and synth.progress < skill.progrmin) or
							 (skill.progrmax > 0 and synth.progress > skill.progrmax) or
							 (skill.qualitymin > 0 and synth.quality < skill.qualitymin) or
							 (skill.qualitymin > 0 and synth.quality > skill.qualitymin) or
							 (skill.condition ~= " " and synth.description ~= skill.condition))
							 then castable = false 
						end
							 
							 
						if ( castable ) then
							d("CASTING : "..tostring(skill.name))								
							if ( ActionList:Cast(skill.id,0) ) then									
								skill.lastcast = ml_global_information.Now
								SkillMgr.prevSkillID = tostring(skill.id)
							end	
						end					
					end
				end
			end
		end
	end
end

function SkillMgr.Gather( )
	
	local node = Player:GetTarget()
	if ( ValidTable(node) and node.cangather and TableSize(SkillMgr.SkillProfile) > 0 and not ActionList:IsCasting()) then
		
		for prio,skill in pairs(SkillMgr.SkillProfile) do
			if ( skill.used == "1" ) then		-- takes care of los, range, facing target and valid target		
				
				local realskilldata = ActionList:Get(skill.id)
				if ( realskilldata and realskilldata.isready ) then 
					if ( realskilldata.isready ) then
						local castable = true
						
						--these first two conditionals here look retarded due to poor naming but they are correct
						if ((skill.gpmin > 0 and Player.gp.current > skill.gpmin) or
							(skill.gpmax > 0 and Player.gp.current < skill.gpmax) or
							(skill.pbuff ~= "" and not HasBuff(Player.id,tonumber(skill.pbuff))) or
							(skill.pnbuff ~= "" and HasBuff(Player.id,tonumber(skill.pnbuff))) or
							(skill.gatherattempts > 0 and node.gatherattempts <= skill.gatherattempts) or
							(skill.hasitem ~="" and not NodeHasItem(skill.hasitem)))
							then castable = false 
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
-- Skillmanager Task for the mainbot & assistmode
ffxiv_task_skillmgrAttack = inheritsFrom(ml_task)
function ffxiv_task_skillmgrAttack:Create()
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
    
    return newinst
end


function ffxiv_task_skillmgrAttack:Process()
	local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	if (target ~= nil and target.alive and InCombatRange(target.id)) then
		
		local pos = target.pos
		Player:SetFacing(pos.x,pos.y,pos.z)
		Player:SetTarget(ml_task_hub:CurrentTask().targetid)
		local cast = false
		
		if (Player.hp.percent < 70 )then
			cast = SkillMgr.Cast( Player )
		end
		if not cast then			
			SkillMgr.Cast( target )
		end
	else
		self.targetid = 0
		self.completed = true
	end
end

function ffxiv_task_skillmgrAttack:OnSleep()

end

function ffxiv_task_skillmgrAttack:OnTerminate()

end

function ffxiv_task_skillmgrAttack:IsGoodToAbort()

end

function ffxiv_task_skillmgrAttack:task_complete_eval()
	local target = Player:GetTarget()
    if (target == nil or not target.alive or not target.attackable or target.distance > ml_global_information.AttackRange) then
        return true
    end
    
    return false
end

function ffxiv_task_skillmgrAttack:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

-- SkillMgr Heal Task
ffxiv_task_skillmgrHeal = inheritsFrom(ml_task)
function ffxiv_task_skillmgrHeal:Create()
    local newinst = inheritsFrom(ffxiv_task_skillmgrHeal)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_SM_HEAL"
    newinst.targetid = 0
    
    return newinst
end


function ffxiv_task_skillmgrHeal:Process()
	
	if ( ml_task_hub.CurrentTask().targetid ~= nil and ml_task_hub.CurrentTask().targetid ~= 0 ) then
		local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
		if (target ~= nil and target.alive and target.hp.percent < 95 and target.distance <= ml_global_information.AttackRange) then
			
			SkillMgr.Cast( target )
			
		end
	end
	-- test if these 2 are needed or if eval complete does the job ...
	self.targetid = 0
	self.completed = true
end

function ffxiv_task_skillmgrHeal:OnSleep()

end

function ffxiv_task_skillmgrHeal:OnTerminate()

end

function ffxiv_task_skillmgrHeal:IsGoodToAbort()

end

function ffxiv_task_skillmgrHeal:task_complete_eval()
	local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
    if (target == nil or not target.alive or target.hp.percent > 95 or target.distance > ml_global_information.AttackRange) then
        return true
    end
    
    return false
end

function ffxiv_task_skillmgrHeal:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

RegisterEventHandler("Gameloop.Update",SkillMgr.OnUpdate)
RegisterEventHandler("SkillManager.toggle", SkillMgr.ToggleMenu)
RegisterEventHandler("GUI.Update",SkillMgr.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",SkillMgr.ModuleInit)
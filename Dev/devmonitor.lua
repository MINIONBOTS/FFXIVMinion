Dev = { }
Dev.lastticks = 0
Dev.running = false
Dev.curTask = nil


function Dev.ModuleInit()
	GUI_NewWindow("Dev",400,50,250,430)
	--Player Information
	GUI_NewField("Dev","ptr","player_ptr","PlayerInfo")
	GUI_NewField("Dev","id","player_id","PlayerInfo")
	GUI_NewField("Dev","name","player_name","PlayerInfo")
	GUI_NewField("Dev","type","player_type","PlayerInfo")
	GUI_NewField("Dev","chartype","player_chartype","PlayerInfo")
	GUI_NewField("Dev","targetid","player_targetid","PlayerInfo")
	GUI_NewField("Dev","status","player_status","PlayerInfo")	
	GUI_NewField("Dev","incombat","player_incombat","PlayerInfo")
	GUI_NewField("Dev","revivestate","player_revivestate","PlayerInfo")
	GUI_NewField("Dev","role","player_role","PlayerInfo")
	GUI_NewField("Dev","hasaggro","player_hasaggro","PlayerInfo")
	GUI_NewField("Dev","localmapid","player_localmapid","PlayerInfo")
	GUI_NewField("Dev","pos.x","player_posX","PlayerInfo")
	GUI_NewField("Dev","pos.y","player_posY","PlayerInfo")
	GUI_NewField("Dev","pos.z","Player_posZ","PlayerInfo")
	GUI_NewField("Dev","pos.h","player_posH","PlayerInfo")
	GUI_NewField("Dev","onmesh","player_onmesh","PlayerInfo")
	GUI_NewField("Dev","hp","player_hp","PlayerInfo")
	GUI_NewField("Dev","mp","player_mp","PlayerInfo")
	GUI_NewField("Dev","tp","player_tp","PlayerInfo")
	GUI_NewField("Dev","cp","player_cp","PlayerInfo")
	GUI_NewField("Dev","gp","player_gp","PlayerInfo")
	GUI_NewField("Dev","level","player_level","PlayerInfo")
	GUI_NewField("Dev","job","player_job","PlayerInfo")	
	GUI_NewField("Dev","fateid","player_fateid","PlayerInfo")
	GUI_NewField("Dev","action","player_action","PlayerInfo")
	GUI_NewField("Dev","lastaction","player_lastaction","PlayerInfo")	
	GUI_NewField("Dev","channelingid","player_channelingid","PlayerInfo")	
	GUI_NewField("Dev","channeltime","player_channeltime","PlayerInfo")	
	GUI_NewField("Dev","channeltargetid","player_channeltargetid","PlayerInfo")
	GUI_NewField("Dev","castingid","player_castingid","PlayerInfo")	
	GUI_NewField("Dev","casttime","player_casttime","PlayerInfo")
	GUI_NewField("Dev","castingtargetcount","player_castingtargetcount","PlayerInfo")
	
	--TargetInfo
	GUI_NewField("Dev","ptr","target_ptr","TargetInfo")
	GUI_NewField("Dev","id","target_id","TargetInfo")
	GUI_NewField("Dev","name","target_name","TargetInfo")
	GUI_NewField("Dev","type","target_type","TargetInfo")
	GUI_NewField("Dev","chartype","target_chartype","TargetInfo")
	GUI_NewField("Dev","ownerid","target_ownerid","TargetInfo")
	GUI_NewField("Dev","targetid","target_targetid","TargetInfo")
	GUI_NewField("Dev","contentid","target_contentid","TargetInfo")
	GUI_NewField("Dev","uniqueid","target_uniqueid","TargetInfo")
	GUI_NewField("Dev","status","target_status","TargetInfo")	
	GUI_NewField("Dev","targetable","target_targetable","TargetInfo")
	GUI_NewField("Dev","attackable","target_attackable","TargetInfo")
	GUI_NewField("Dev","los","target_los","TargetInfo")
	GUI_NewField("Dev","aggressive","target_aggressive","TargetInfo")
	GUI_NewField("Dev","friendly","target_friendly","TargetInfo")
	GUI_NewField("Dev","aggro","target_aggro","TargetInfo")
	GUI_NewField("Dev","aggropercentage","target_aggropercentage","TargetInfo")
	GUI_NewField("Dev","incombat","target_incombat","TargetInfo")
	GUI_NewField("Dev","distance (3D)","target_distance","TargetInfo")
	GUI_NewField("Dev","distance2D","target_distance2d","TargetInfo")
	GUI_NewField("Dev","pathdistance","target_pathdistance","TargetInfo")
	GUI_NewField("Dev","hitradius","target_hitradius","TargetInfo")
	GUI_NewField("Dev","InCombatRange()","target_InCombatRange","TargetInfo")
	GUI_NewField("Dev","pos.x","target_posX","TargetInfo")
	GUI_NewField("Dev","pos.y","target_posY","TargetInfo")
	GUI_NewField("Dev","pos.z","target_posZ","TargetInfo")
	GUI_NewField("Dev","pos.h","target_posH","TargetInfo")
	GUI_NewField("Dev","onmesh","target_onmesh","TargetInfo")
	GUI_NewField("Dev","hp","target_hp","TargetInfo")
	GUI_NewField("Dev","mp","target_mp","TargetInfo")
	GUI_NewField("Dev","tp","target_tp","TargetInfo")		
	GUI_NewField("Dev","level","target_level","TargetInfo")
	GUI_NewField("Dev","job","target_job","TargetInfo")
	GUI_NewField("Dev","cangather","target_cangather","TargetInfo")
	GUI_NewField("Dev","gatherattemptsmax","target_gatherattemptsmax","TargetInfo")
	GUI_NewField("Dev","gatherattempts","target_gatherattempts","TargetInfo")
	GUI_NewField("Dev","fateid","target_fateid","TargetInfo")
	GUI_NewField("Dev","action","target_action","TargetInfo")
	GUI_NewField("Dev","lastaction","target_lastaction","TargetInfo")	
	GUI_NewField("Dev","channelingid","target_channelingid","TargetInfo")	
	GUI_NewField("Dev","channeltime","target_channeltime","TargetInfo")	
	GUI_NewField("Dev","channeltargetid","target_channeltargetid","TargetInfo")
	GUI_NewField("Dev","castingid","target_castingid","TargetInfo")	
	GUI_NewField("Dev","casttime","target_casttime","TargetInfo")
	GUI_NewField("Dev","castingtargetcount","target_castingtargetcount","TargetInfo")
	
	-- ActionList
	GUI_NewField("Dev","IsCasting","sbiscast","ActionListInfo")
	GUI_NewComboBox("Dev","TypeFilter","sbSelHotbar","ActionListInfo","Actions,Pet,General,Maincommands,Crafting");
	GUI_NewNumeric("Dev","Spell","sbSelSlot","ActionListInfo","0","999");		
	GUI_NewField("Dev","Name","sbname","ActionListInfo")
	GUI_NewField("Dev","Description","sbdesc","ActionListInfo")
	GUI_NewField("Dev","SkillID","sbid","ActionListInfo")
	GUI_NewField("Dev","IsReady","sbready","ActionListInfo")
	GUI_NewField("Dev","Type","sbtype","ActionListInfo")
	GUI_NewField("Dev","JobType","sbjobtype","ActionListInfo")
	GUI_NewField("Dev","Level","sblevel","ActionListInfo")
	GUI_NewField("Dev","TP/MP Cost","sbcost","ActionListInfo")
	GUI_NewField("Dev","Cooldown","sbcd","ActionListInfo")
	GUI_NewField("Dev","MaxCooldown","sbcdmax","ActionListInfo")
	GUI_NewField("Dev","IsOnCooldown","sbisoncd","ActionListInfo")
	GUI_NewField("Dev","Range","sbran","ActionListInfo")
	GUI_NewField("Dev","Radius","sbrad","ActionListInfo")
	GUI_NewField("Dev","Casttime","sbct","ActionListInfo")
	GUI_NewField("Dev","Recasttime","sbrct","ActionListInfo")
	GUI_NewField("Dev","CanCast","sbcanc","ActionListInfo")
	GUI_NewField("Dev","CanCastOnTarget","sbcancast","ActionListInfo")
	GUI_NewButton("Dev","Cast","Dev.Cast","ActionListInfo")
	sbSelSlot = 0		
	sbSelHotbar = "Actions"
	sbpendingcast = false
	
	GUI_NewComboBox("Dev","Inventory","invinv","InventoryInfo","0,1,2,3,1000,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500,10000,10001,10002,10003,10004,10005,10006,11000,12000,12001,12002");	
	GUI_NewNumeric("Dev","SlotNumber","invSelSlot","InventoryInfo","1","199");
	GUI_NewField("Dev","Ptr","invptr","InventoryInfo")
	GUI_NewField("Dev","Ptr2","invptr2","InventoryInfo")
	GUI_NewField("Dev","ID","invid","InventoryInfo")
	GUI_NewField("Dev","Name/Desc","invname","InventoryInfo")
	GUI_NewField("Dev","InvType","invtype","InventoryInfo")
	GUI_NewField("Dev","InvSlot","invslot","InventoryInfo")
	GUI_NewField("Dev","Stackcount","invcount","InventoryInfo")
	GUI_NewField("Dev","MaxStackcount","invmaxcount","InventoryInfo")
	GUI_NewField("Dev","Condition","invcond","InventoryInfo")
	GUI_NewField("Dev","Level","invlvl","InventoryInfo")
	GUI_NewField("Dev","RequiredLevel","invreqlvl","InventoryInfo")
	GUI_NewButton("Dev","UseItem","Dev.UseItem","InventoryInfo")	
	invSelSlot = 0
	invinv = "0"
	
	-- Bufflist 
	GUI_NewComboBox("Dev","BuffList of","btarg","BuffInfo","Player,Target");	
	GUI_NewNumeric("Dev","BuffAtIndex","bpSelSlot","BuffInfo","1","199");
	GUI_NewField("Dev","ID","bpid","BuffInfo")
	GUI_NewField("Dev","ownerID","bpownid","BuffInfo")
	GUI_NewField("Dev","slot","bpslot","BuffInfo")
	GUI_NewField("Dev","Name","bpname","BuffInfo")
	GUI_NewField("Dev","Duration","bpdur","BuffInfo")
	btarg = "Player"
	bpSelSlot = 0
	
	--Movement Info
	GUI_NewField("Dev","IsMoving","mimov","MovementInfo")
	GUI_NewField("Dev","Moves Forward","mimovf","MovementInfo")
	GUI_NewField("Dev","Moves Backward","mimovb","MovementInfo")
	GUI_NewField("Dev","Moves Left","mimovl","MovementInfo")
	GUI_NewField("Dev","Moves Right","mimovr","MovementInfo")
	GUI_NewButton("Dev","MoveForward","Dev.MoveF","MovementInfo")
	GUI_NewButton("Dev","MoveBackward","Dev.MoveB","MovementInfo")
	GUI_NewButton("Dev","MoveLeft","Dev.MoveL","MovementInfo")
	GUI_NewButton("Dev","MoveRight","Dev.MoveR","MovementInfo")
	GUI_NewButton("Dev","Stop","Dev.MoveS","MovementInfo")
	GUI_NewNumeric("Dev","Set Speed","mimovss","MovementInfo")
	GUI_NewComboBox("Dev","Set SpeedDirection","mimovssdir","MovementInfo","Forward,Backward,Left,Right");
	GUI_NewButton("Dev","Set Speed","Dev.SetSpeed","MovementInfo")
	mimovss = 0
	mimovssdir = "Forward"
		
	
	-- Navigation functions
	GUI_NewField("Dev","X: ","tb_xPos","NavigationSystem")
	GUI_NewField("Dev","Y: ","tb_yPos","NavigationSystem")
	GUI_NewField("Dev","Z: ","tb_zPos","NavigationSystem")
	GUI_NewButton("Dev","GetCurrentPos","Dev.playerPosition","NavigationSystem")	
	GUI_NewField("Dev","NavigateTo Result:","tb_nRes","NavigationSystem")
	GUI_NewButton("Dev","NavigateTo","Dev.naviTo","NavigationSystem")
	GUI_NewButton("Dev","MoveToStraight","Dev.moveTo","NavigationSystem")
	GUI_NewButton("Dev","Teleport","Dev.teleport","NavigationSystem")
	tb_nPoints = 0
	
	-- AetheryteList
	GUI_NewNumeric("Dev","ListIndex","aesel","AetheryteList","1","99")
	GUI_NewField("Dev","Ptr","aeptr","AetheryteList")
	GUI_NewField("Dev","Index","aeidx","AetheryteList")	
	GUI_NewField("Dev","Region","aeregion","AetheryteList")
	GUI_NewField("Dev","Map Name","aename","AetheryteList")
	GUI_NewField("Dev","Map ID","aeterr","AetheryteList")
	GUI_NewField("Dev","IsHomepoint","aeishp","AetheryteList")
	GUI_NewField("Dev","IsFavorite","aeisfav","AetheryteList")
	GUI_NewField("Dev","IsInLocalMap","aeisloc","AetheryteList")
	aesel = 0
	
	-- FateInfo
	GUI_NewNumeric("Dev","FateIndex","faidx","FateInfo","1","20")	
	GUI_NewField("Dev","P","faptr","FateInfo")
	GUI_NewField("Dev","ID","faid","FateInfo")
	GUI_NewField("Dev","TargetFID","tfaid","FateInfo")
	GUI_NewField("Dev","Name","faname","FateInfo")
	GUI_NewField("Dev","Desc","fadesc","FateInfo")
	GUI_NewField("Dev","Status","fastat","FateInfo")
	GUI_NewField("Dev","Completion","facompl","FateInfo")
	GUI_NewField("Dev","Type","fatype","FateInfo")
	GUI_NewField("Dev","Level","falvl","FateInfo")	
	GUI_NewField("Dev","Pos","fapos","FateInfo")
	GUI_NewField("Dev","Radius","farad","FateInfo")
	GUI_NewField("Dev","Duration","fdur","FateInfo")
	GUI_NewField("Dev","Synced FateLevel","fasynclvl","FateInfo")
	GUI_NewButton("Dev","Sync Fate Level","Dev.Sync","FateInfo")
	faidx = 0
	fasynclvl = 0
	
	-- FishingInfo
	GUI_NewField("Dev","BaitItemID","fishbait","FishingInfo")
	GUI_NewField("Dev","SetBaitID","fishsbait","FishingInfo")
	GUI_NewButton("Dev","SetBaitID","Dev.Bait","FishingInfo")
	GUI_NewField("Dev","FishingState","fishstate","FishingInfo")
	GUI_NewField("Dev","CanCast","fishcs","FishingInfo")
	GUI_NewButton("Dev","Start Fishing","Dev.Fish","FishingInfo")
	fishsbait = 0
	
	-- Gathering
	GUI_NewNumeric("Dev","GatherItem","gaidx","GatheringInfo","1","8");
	GUI_NewField("Dev","Ptr open","gaptr","GatheringInfo")
	GUI_NewField("Dev","ItemID","gaid","GatheringInfo")
	GUI_NewField("Dev","Name","ganame","GatheringInfo")
	GUI_NewField("Dev","Chance","gachan","GatheringInfo")
	GUI_NewField("Dev","HQchance","gahqchan","GatheringInfo")
	GUI_NewField("Dev","Level","galevel","GatheringInfo")
	GUI_NewField("Dev","Description","gadesc","GatheringInfo")
	GUI_NewField("Dev","Index","gaindex","GatheringInfo")
	GUI_NewButton("Dev","Gather Item","Dev.Gather","GatheringInfo")
	gaidx = 1
	
	-- Crafting
	GUI_NewNumeric("Dev","Amount to Craft","cramount","CraftingInfo","1","9999");
	GUI_NewField("Dev","ItemID","crid","CraftingInfo")
	GUI_NewField("Dev","Step","crst","CraftingInfo")
	GUI_NewField("Dev","StepMax","crstm","CraftingInfo")	
	GUI_NewField("Dev","Durability","crdu","CraftingInfo")
	GUI_NewField("Dev","DurabilityMax","crdum","CraftingInfo")
	GUI_NewField("Dev","Progress","crpr","CraftingInfo")
	GUI_NewField("Dev","ProgressMax","crprm","CraftingInfo")
	GUI_NewField("Dev","Quality","crqu","CraftingInfo")
	GUI_NewField("Dev","QualityMax","crqum","CraftingInfo")
	GUI_NewField("Dev","Text","crtext","CraftingInfo")	
	GUI_NewField("Dev","CraftingLogOpen","cropen","CraftingInfo")	
	GUI_NewField("Dev","CanCraftSelectedItem","crcan","CraftingInfo")
	GUI_NewButton("Dev","ToggleCraftingLog","Dev.CraftLog","CraftingInfo")
	GUI_NewButton("Dev","CraftSelectedItem","Dev.Craft","CraftingInfo")
	
	-- Respawn_Teleportinfo
	GUI_NewField("Dev","RespawnState","resState","Respawn_Teleportinfo")
	GUI_NewButton("Dev","Respawn","Dev.Rezz","Respawn_Teleportinfo")
	
	--Partymember
	GUI_NewNumeric("Dev","Partymember","pamem","PartyInfo","0","10");	
	GUI_NewField("Dev","ptr","pptr","PartyInfo")
	GUI_NewField("Dev","name","paname","PartyInfo")
	GUI_NewField("Dev","id","paid","PartyInfo")
	GUI_NewField("Dev","region","pareg","PartyInfo")
	GUI_NewField("Dev","mapid","pacid","PartyInfo")
	GUI_NewField("Dev","isleader","palead","PartyInfo")	
	GUI_NewField("Dev","onmesh","paonmesh","PartyInfo")			
	GUI_NewField("Dev","pos","papos","PartyInfo")	
	pamem = 0
	
	--DutyFinder/PvP
	GUI_NewField("Dev","DutySelectWindow","duty_selectwindow","DutyInfo")
	GUI_NewField("Dev","ConfirmEnterWindow","duty_confirmenterwindow","DutyInfo")
	GUI_NewField("Dev","YesNoWindow","duty_yesnowindow","DutyInfo")
	GUI_NewField("Dev","IsLoading","duty_IsLoading","DutyInfo")
	GUI_NewField("Dev","TaskName","duty_taskname","DutyInfo")
	GUI_NewField("Dev","TaskState","duty_taskstate","DutyInfo")
	GUI_NewField("Dev","Encounter","duty_taskencounter","DutyInfo")
	
	GUI_NewButton("Dev","PressDutyConfirm","Dev.DConf","DutyInfo")
	GUI_NewButton("Dev","PressLeaveColosseum","Dev.PressLeaveColosseum","DutyInfo")
	
	--QuestInfo
	GUI_NewNumeric("Dev","Quest","QIindex","QuestInfo","0","200");
	GUI_NewField("Dev","ID","QIID","QuestInfo")
	GUI_NewField("Dev","Name","QIName","QuestInfo")
	GUI_NewField("Dev","Step","QIStep","QuestInfo")
	GUI_NewField("Dev","QuestI8A","QuestI8A","QuestInfo")
	GUI_NewField("Dev","QuestI8B","QuestI8B","QuestInfo")
	GUI_NewField("Dev","QuestI8C","QuestI8C","QuestInfo")
	GUI_NewField("Dev","QuestI8D","QuestI8D","QuestInfo")
	GUI_NewField("Dev","QuestI8E","QuestI8E","QuestInfo")
	GUI_NewField("Dev","QuestI8F","QuestI8F","QuestInfo")
	
	GUI_NewField("Dev","QuestI8AH","QuestI8AH","QuestInfo")
	GUI_NewField("Dev","QuestI8BH","QuestI8BH","QuestInfo")
	GUI_NewField("Dev","QuestI8CH","QuestI8CH","QuestInfo")
	GUI_NewField("Dev","QuestI8DH","QuestI8DH","QuestInfo")
	GUI_NewField("Dev","QuestI8EH","QuestI8EH","QuestInfo")
	GUI_NewField("Dev","QuestI8FH","QuestI8FH","QuestInfo")
	
	GUI_NewField("Dev","QuestI8AL","QuestI8AL","QuestInfo")
	GUI_NewField("Dev","QuestI8BL","QuestI8BL","QuestInfo")
	GUI_NewField("Dev","QuestI8CL","QuestI8CL","QuestInfo")
	GUI_NewField("Dev","QuestI8DL","QuestI8DL","QuestInfo")
	GUI_NewField("Dev","QuestI8EL","QuestI8EL","QuestInfo")
	GUI_NewField("Dev","QuestI8FL","QuestI8FL","QuestInfo")
	
	GUI_NewField("Dev","QuestI16A","QuestI16A","QuestInfo")
	GUI_NewField("Dev","QuestI16B","QuestI16B","QuestInfo")
	GUI_NewField("Dev","QuestI16C","QuestI16C","QuestInfo")
	
	GUI_NewField("Dev","QuestBit8","QuestBit8","QuestInfo")
	GUI_NewField("Dev","QuestBit16","QuestBit16","QuestInfo")
	GUI_NewField("Dev","QuestBit24","QuestBit24","QuestInfo")
	GUI_NewField("Dev","QuestBit32","QuestBit32","QuestInfo")
	GUI_NewField("Dev","QuestBit40","QuestBit40","QuestInfo")
	GUI_NewField("Dev","QuestBit48","QuestBit48","QuestInfo")
	
	
	GUI_NewButton("Dev","AcceptQuest","Dev.QuestAQ","QuestInfo")
	GUI_NewButton("Dev","DeclineQuest","Dev.QuestDQ","QuestInfo")	
	GUI_NewField("Dev","IsQuestAcceptDialogOpen","QIIsQADO","QuestInfo")
	GUI_NewButton("Dev","RequestHandOver","Dev.QuestRHO","QuestInfo")
	GUI_NewButton("Dev","RequestCancel","Dev.QuestRC","QuestInfo")	
	GUI_NewField("Dev","IsQuestRewardDialogOpen","QIIsQRDO","QuestInfo")
	GUI_NewButton("Dev","CompleteQuestReward","Dev.QuestCQR","QuestInfo")
	GUI_NewButton("Dev","DeclineQuestReward","Dev.QuestDQR","QuestInfo")	
	GUI_NewField("Dev","IsLoading","QIIsLoading","QuestInfo")
	GUI_NewField("Dev","IsInDialog","QIIsDialog","QuestInfo")
	QIindex = 0
	
	-- General Functions
	GUI_NewField("Dev","Text Command","general_sendtextcommand","General Functions")
	GUI_NewButton("Dev","Send Text Command","Dev.SendTextCommand","General Functions")
	GUI_NewButton("Dev","Repair","Dev.Repair", "General Functions")
	GUI_NewButton("Dev","Interact with Target","Dev.Interact","General Functions")
	GUI_NewButton("Dev","Follow Target","Dev.Follow","General Functions")
	GUI_NewNumeric("Dev","Sound","gsound","General Functions","0","71");
	GUI_NewButton("Dev","PlaySound","Dev.Sound","General Functions")
	gsound = 0
	GUI_WindowVisible("Dev",false)
	
	GUI_NewButton("Dev","TOGGLE DEVMONITOR ON_OFF","Dev.Test2")
	GUI_SizeWindow("Dev",250,550)		
end

function Dev.HandleButtons( Event, arg )	
	if ( Event == "GUI.Item" ) then
		if ( arg == "Dev.QuestCQR") then
			d(Quest:CompleteQuestReward())
		elseif ( arg == "Dev.QuestDQR") then
			d(Quest:DeclineQuestReward())
		elseif ( arg == "Dev.QuestRHO") then
			d(Quest:RequestHandOver())
		elseif ( arg == "Dev.QuestRC") then
			d(Quest:RequestCancel())
		elseif ( arg == "Dev.QuestAQ") then
			d(Quest:AcceptQuest())
		elseif ( arg == "Dev.QuestDQ") then
			d(Quest:DeclineQuest())
		elseif ( arg == "Dev.UseItem") then	
			local inv = Inventory("type="..invinv)
			if ( inv ) then
				local item = inv[tonumber(invSelSlot)]
				if ( item ) then
					local tar = Player:GetTarget()
					if ( tar ) then
						d(item:Use(tar.id))
					else
						d(item:Use())
					end					
				end
			end			
		elseif ( arg == "Dev.Interact") then
			local t = Player:GetTarget()
			if ( t ) then
				Player:Interact(t.id)
			end		
		elseif ( arg == "Dev.Follow") then
			local t = Player:GetTarget()
			if ( t ) then
				Player:FollowTarget(t.id)
			end			
		elseif ( arg == "Dev.Fish") then
			Dev.curTask = Dev.FishTask	
		elseif ( arg == "Dev.Bait") then
			if ( tonumber(fishsbait) > 0 ) then
				d(Player:SetBait(tonumber(fishsbait)))
			end
		elseif ( arg == "Dev.Rezz") then
			d(Player:Respawn())
		elseif ( arg == "Dev.Gather" ) then
			d(Player:Gather(tonumber(gaindex)))
		elseif ( arg == "Dev.Cast" ) then
			sbpendingcast = true
		elseif ( arg == "Dev.Craft" ) then
			Dev.curTask = Dev.CraftTask	
		elseif ( arg == "Dev.CraftLog" ) then	
			Crafting:ToggleCraftingLog()
		elseif ( arg == "Dev.Sync" ) then
			Player:SyncLevel()
		elseif ( arg == "Dev.Sound" ) then
			GameHacks:PlaySound(tonumber(gsound))
		elseif ( arg == "Dev.DConf") then
			d(PressDutyConfirm(true))
		elseif ( arg == "Dev.PressLeaveColosseum") then
			d(PressLeaveColosseum())
		elseif ( arg == "Dev.MoveF") then
			Player:Move(FFXIV.MOVEMENT.FORWARD)
		elseif ( arg == "Dev.MoveB") then
			Player:Move(FFXIV.MOVEMENT.BACKWARD)
		elseif ( arg == "Dev.MoveL") then
			Player:Move(FFXIV.MOVEMENT.LEFT)
		elseif ( arg == "Dev.MoveR") then
			Player:Move(FFXIV.MOVEMENT.RIGHT)
		elseif ( arg == "Dev.MoveS") then
			Player:Stop()
		elseif ( dir == "Dev.SetSpeed" and tonumber(mimovss) > 0) then
			if ( mimovssdir == "Forward" ) then
				Player:SetSpeed(FFXIV.MOVEMENT.FORWARD, tonumber(mimovss))
			elseif ( mimovssdir == "Backward" ) then
				Player:SetSpeed(FFXIV.MOVEMENT.BACKWARD, tonumber(mimovss))
			elseif ( mimovssdir == "Left" ) then
				Player:SetSpeed(FFXIV.MOVEMENT.LEFT, tonumber(mimovss))
			elseif ( mimovssdir == "Right" ) then
				Player:SetSpeed(FFXIV.MOVEMENT.RIGHT, tonumber(mimovss))
			end	
		elseif ( arg == "Dev.playerPosition") then
				local p = Player.pos
				tb_xPos = tostring(p.x)
				tb_yPos = tostring(p.y)
				tb_zPos = tostring(p.z)
		elseif ( arg == "Dev.naviTo") then
			tb_nRes = tostring(Player:MoveTo(tonumber(tb_xPos),tonumber(tb_yPos),tonumber(tb_zPos)))
		elseif ( arg == "Dev.moveTo") then
			Player:MoveToStraight(tonumber(tb_xPos),tonumber(tb_yPos),tonumber(tb_zPos))
		elseif ( arg == "Dev.teleport") then
			d("Teleporting to : "..tostring(tb_xPos).." "..tostring(tb_yPos).." "..tostring(tb_zPos))
			d(GameHacks:TeleportToXYZ(tonumber(tb_xPos),tonumber(tb_yPos),tonumber(tb_zPos)))
		elseif ( arg == "Dev.SendTextCommand" ) then
			SendTextCommand(general_sendtextcommand)
		elseif ( arg == "Dev.Repair" ) then
			local eq = Inventory("type=1000")
			if (eq) then
				local i,e = next (eq)
				while ( i and e ) do					
					d("R: "..tostring(e.name .. " " ..tostring(e.slot)))
					e:Repair()
					i,e = next (eq,i)
				end		
			end
		end
	end
end

function Dev.FishTask()
	local fs = tonumber(Player:GetFishingState())
	if ( fs == 0 or fs == 4 ) then -- FISHSTATE_NONE or FISHSTATE_POLEREADY
		ActionList:Cast(289,0) --fish skillid 2 
	elseif( fs == 5 ) then -- FISHSTATE_BITE
		ActionList:Cast(296,0) -- Hook, skill 3   (129 is some other hook skillid ??	
	end
end


Dev.SteadyHandUsed = false
function Dev.CraftTask()
 local synth = Crafting:SynthInfo()
 if ( synth ) then
	if (synth.durabilitymax > 0) then
		if (true) then -- armorer
			if ( synth.durability >= 30 and Player.cp.current > 32) then
				if ( Player.cp.current >= 64 and not HasBuff(Player.id, 253 ) ) then
					d("buff up...")
					ActionList:Cast(247,0)
				else
					d("qual up...")
				
					if ( Player.cp.current >= 18 ) then
					 --  ActionList:Cast(100034,0)
					--else
						ActionList:Cast(100076,0)
					--else
					end
				end
			elseif ( synth.durability == 10 and Player.cp.current > 92 ) then
				d("dur up...")
				ActionList:Cast(100077,0)
			--elseif (false and Player.cp.current > 15 ) then
			-- d("std synt...")
			-- ActionList:Cast(100007,0)
			else
				 d("cheap synt...")
				 ActionList:Cast(100075,0)
			end
		elseif (false) then -- armorer
    if ( synth.durability >= 30 and Player.cp.current > 32) then
     if ( Player.cp.current >= 64 and not HasBuff(Player.id, 253 ) ) then
      d("buff up...")
      ActionList:Cast(246,0)
     else
      d("qual up...")
      if ( Player.cp.current >= 32 ) then
       ActionList:Cast(100034,0)
      else
       ActionList:Cast(100031,0)
      end
     end
    elseif ( synth.durability == 10 and Player.cp.current > 92 ) then
     d("dur up...")
     ActionList:Cast(100032,0)
    elseif (false and Player.cp.current > 15 ) then
     d("std synt...")
     ActionList:Cast(100007,0)
    else
     d("cheap synt...")
     ActionList:Cast(100030,0)
    end
   elseif (false) then -- crapenter
   -- normal crafting
    if ( synth.durability >= 30 and Player.cp.current > 32) then
     if ( Player.cp.current >= 64 and not HasBuff(Player.id, 254 ) ) then
      d("buff up...")
      ActionList:Cast(260,0)
     else
      d("qual up...")
      if ( Player.cp.current >= 48 ) then
       ActionList:Cast(100008,0)
      else
       ActionList:Cast(100004,0)
      end
     end
    elseif ( synth.durability == 10 and Player.cp.current > 92 ) then
     d("dur up...")
     ActionList:Cast(100003,0)
    elseif (false and Player.cp.current > 15 ) then
     d("std synt...")
     ActionList:Cast(100007,0)
    else
     d("cheap synt...")
     ActionList:Cast(100001,0)
    end
   elseif (false) then  --leatherworker
    -- 279 waste not
    if ( synth.durability == 10 and Player.cp.current > 92 ) then
     d("dur up...")
     ActionList:Cast(100047,0)
    elseif (synth.durability >= 40 and Player.cp.current >= 200 and  not HasBuff(Player.id, 252 )  ) then
     ActionList:Cast(279,0)
   elseif (synth.durability > 20 and Player.cp.current >= 92+32 ) then
     -- 100046 Basic Touch
     ActionList:Cast(100048,0)
    elseif (synth.durability > 20 and Player.cp.current >= 92+18 ) then
      --100046 Basic Touch
     ActionList:Cast(100046,0)
    else
     ActionList:Cast(100045,0)
    end
   elseif (false) then --weaver
    if ( synth.durability == 10 and Player.cp.current > 92 ) then
     d("dur up...")
     ActionList:Cast(100062,0)
    elseif (synth.durability >= 40 and Player.cp.current >= 18) then
     ActionList:Cast(100061,0)
    elseif (synth.durability > 20 and Player.cp.current >= 92+32 ) then
     -- 100064 Basic Touch
     ActionList:Cast(100064,0)    
    else    
     ActionList:Cast(100060,0)
    end
   elseif (false) then
    -- goldsmith
    
    ActionList:Cast(100075,0)
   
   end
   
   
  else
   -- quicksynth
   if ( synth.step == synth.stepmax ) then
    Crafting:EndSynthesis()
   end
  end
  Dev.lastticks = Dev.lastticks + 1000
 else
  if (not Crafting:IsCraftingLogOpen()) then
   Crafting:ToggleCraftingLog()
  else
   local eq = Inventory("type=1000")
   if (eq) then
    local i,e = next (eq)
    while ( i and e ) do
     if ( e.condition < 10 ) then
      d("R: "..tostring(e.name .. " " ..tostring(e.slot)))
      Inventory:Repair(1000,e.slot)
     end
     i,e = next (eq,i)
    end  
   end
   d("Crafting Item...")
   if ( tonumber(cramount) > 1 ) then
    Crafting:CraftSelectedItem(tonumber(cramount))
   else
    Crafting:CraftSelectedItem()
   end
   Crafting:ToggleCraftingLog()
   Dev.lastticks = Dev.lastticks + 3000
   Dev.SteadyHandUsed = false
  end
 end 
end

function Dev.Test2()
	Dev.running = not Dev.running
	if ( not Dev.running) then Dev.curTask = nil end
	d(Dev.running)
end
			
function Dev.UpdateWindow()
	
	local p = Player
	local ppos = Player.pos
	
	player_ptr = string.format( "%x",tonumber(p.ptr ))
	player_id = p.id
	player_name = p.name
	player_type = p.type
	player_chartype = p.chartype
	player_targetid = p.targetid
	player_status = p.status
	player_incombat = tostring(p.incombat)
	player_revivestate = p.revivestate
	player_role = p.role
	player_hasaggro = tostring(p.hasaggro)
	player_localmapid = p.localmapid
	player_posX = ppos.x
	player_posY = ppos.y
	Player_posZ = ppos.z
	player_posH = ppos.h
	player_onmesh = tostring(p.onmesh)
	player_hp = tostring(tostring(p.hp.current).." / "..tostring(p.hp.max).." / "..tostring(p.hp.percent).."%")	
	player_mp = tostring(tostring(p.mp.current).." / "..tostring(p.mp.max).." / "..tostring(p.mp.percent).."%")
	player_tp = tostring(p.tp)
	player_cp = tostring(tostring(p.cp.current).." / "..tostring(p.cp.max).." / "..tostring(p.cp.percent).."%")
	player_gp = tostring(tostring(p.gp.current).." / "..tostring(p.gp.max).." / "..tostring(p.gp.percent).."%")
	player_level = p.level
	player_job = p.job	
	player_fateid = p.fateid
	player_action = p.action
	player_lastaction = p.lastaction
	
	if (ValidTable(p.castinginfo)) then
		local ci = p.castinginfo
		player_channelingid = ci.channelingid or 0
		player_channeltime = ci.channeltime or 0
		player_channeltargetid = ci.channeltargetid or 0
		player_castingid = ci.castingid or 0
		player_casttime = ci.casttime or 0
		player_castingtargetcount = ci.castingtargetcount or 0
	end
	
	local target = Player:GetTarget() 
	if (ValidTable(target)) then	
		target_ptr = string.format( "%x",tonumber(target.ptr ))
		target_id = target.id
		target_type = target.type
		target_chartype = target.chartype
		target_name = target.name
		target_ownerid = target.ownerid
		target_targetid = target.targetid
		target_contentid = target.contentid
		target_uniqueid = target.uniqueid
		target_status = target.status--string.format( "%x",tonumber(target.status ))
		target_targetable = tostring(target.targetable)
		target_los = tostring(target.los)
		target_aggro = tostring(target.aggro)
		local agp = EntityList.aggrolist
		if (ValidTable(agp)) then
			for i,entity in pairs(agp) do
				if entity.id == target.id then
					target_aggropercentage = entity.aggropercentage
				end
			end
		end
		--target_aggropercentage = target.aggropercentage
		target_attackable = tostring(target.attackable)
		target_aggressive = tostring(target.aggressive)
		target_friendly = tostring(target.friendly)
		target_incombat = tostring(target.incombat)
		target_distance = (math.floor(target.distance * 10) / 10)
		target_distance2d = (math.floor(target.distance2d * 10) / 10)
		target_pathdistance = (math.floor(target.pathdistance * 10) / 10)
		target_InCombatRange = tostring(InCombatRange(target.id))
		target_hitradius = target.hitradius
		target_onmesh = tostring(target.onmesh)
		target_posX = (math.floor(target.pos.x * 10) / 10)
		target_posY = (math.floor(target.pos.y * 10) / 10)
		target_posZ = (math.floor(target.pos.z * 10) / 10)
		target_posH = (math.floor(target.pos.h * 10) / 10)
		target_hp = tostring(target.hp.current.." / "..target.hp.max.." / "..target.hp.percent.."%")	
		target_mp = tostring(target.mp.current.." / "..target.mp.max.." / "..target.mp.percent.."%")	
		target_tp = tostring(target.tp)	
		
		target_level = target.level
		target_job = target.job
		target_cangather = tostring(target.cangather)
		target_gatherattemptsmax = target.cangatherattemptsmax
		target_gatherattempts = target.gatherattempts
		target_fateid = target.fateid or 0
		target_action = target.action
		target_lastaction = target.lastaction
		
		if (ValidTable(target.castinginfo)) then
			local ci = target.castinginfo
			target_channelingid = ci.channelingid or 0
			target_channeltime = ci.channeltime or 0
			target_channeltargetid = ci.channeltargetid or 0
			target_castingid = ci.castingid or 0
			target_casttime = ci.casttime or 0
			target_castingtargetcount = ci.castingtargetcount or 0
		end
	end
	
	--ActionList	
	
	local spelllist
	local sfound = false
	if  sbSelHotbar == "Actions"  then
		spelllist = ActionList("type=1")	
	elseif  sbSelHotbar == "Pet"  then
		spelllist = ActionList("type=11")
	elseif  sbSelHotbar == "General"  then
		spelllist = ActionList("type=5")	
	elseif  sbSelHotbar == "Maincommands"  then
		spelllist = ActionList("type=10")	
	elseif  sbSelHotbar == "Crafting"  then
		spelllist = ActionList("type=9")
	end
		
	
	if ( TableSize(spelllist) > 0 ) then
		local i,spell = next (spelllist)
		local counter = 0
		while i~=nil and spell~=nil do
			if ( counter == tonumber(sbSelSlot) ) then
				sfound = true
				break
			end
			counter = counter + 1
			i,spell = next (spelllist,i)
		end
		if (spell and sfound) then
			sbiscast = spell.iscasting
			sbname = spell.name
			sbdesc = spell.description
			sbid = spell.id
			sbready = tostring(spell.isready)
			sbtype = spell.type
			sbjobtype = tostring(spell.job)
			sblevel = spell.level
			sbcost = spell.cost
			sbcd = spell.cd
			sbcdmax = spell.cdmax
			sbisoncd = tostring(spell.isoncd)
			sbran = spell.range
			sbrad = spell.radius
			sbct = spell.casttime
			sbrct = spell.recasttime
			sbt1 = spell.t1
			sbt2 = spell.t2		
			sbt4 = spell.t4
			sbt5 = spell.t5	
			mytarget = Player:GetTarget() 
			if (mytarget  ~= nil) then
				sbcancast = tostring(ActionList:CanCast(spell.id,mytarget.id))
			else
				sbcancast = "No Target"
			end
			sbcanc = tostring(ActionList:CanCast(spell.id,0))
			if ( sbpendingcast) then
				sbpendingcast = false
				if ( mytarget  ~= nil ) then
					spell:Cast(mytarget.id)
				else
					spell:Cast()
				end
			end
		end
	end
	if ( not sfound ) then
		sbiscast = "false"
		sbname = "NoSpellFound..."
		sbdesc = ""
		sbptr = 0
		sbid = 0
		sbready = 0
		sbtype = 0
		sbjobtype = 0
		sblevel = 0
		sbcost = 0
		sbcd = 0
		sbcdmax = 0
		sbisoncd = "false"
		sbran = 0
		sbrad = 0
		sbct = 0
		sbrct = 0
		sbt1 = 0
		sbt2 = 0		
		sbt4 = 0
		sbt5 = 0
		sbcancast = "No skill"
		sbcanc = "false"
	end
	--]]
	
	--Inventory/ItemList
	local inv = Inventory("type="..invinv)
	local found = false
	if ( inv ) then
		local item = inv[tonumber(invSelSlot)]
		if ( item ) then
			found = true
			invptr = string.format( "%x",tonumber(item.ptr ))
			invptr2 = string.format( "%x",tonumber(item.ptr2 ))
			invid = item.id
			invname = item.name
			invtype = item.type
			invslot = item.slot
			invcount = item.count
			invmaxcount = item.max
			invcond = item.condition
			invlvl = item.level
			invreqlvl = item.requiredlevel
		end
	end
	if (not found) then
		invptr = 0
		invid = 0
		invname = ""
		invtype = 0
		invslot = 0
		invcount = 0
		invmaxcount = 0
		invcond = 0
	end	
	
	
	--Bufflist
	local bs
	local bfound=false
	if ( btarg == "Player" ) then
		bs = Player
	elseif ( mytarget ~=nil ) then
		 bs = mytarget
	end
	if (bs) then
		local bsbuffs = bs.buffs
		if ( bsbuffs ) then
			local bss = bsbuffs[tonumber(bpSelSlot)]
			if ( bss ) then
				bfound = true
				bpid = bss.id
				bpownid = bss.ownerid
				bpslot = bss.slot
				bpname = bss.name
				bpdur = bss.duration
			end
		end
	end
	if not bfound then
		bpid = 0
		bpownid = 0
		bpslot = 0
		bpname = ""
		bpdur = 0
	end
	
	-- Movement
	mimov = tostring(Player:IsMoving())
	mimovf = tostring(Player:IsMoving(FFXIV.MOVEMENT.FORWARD)).."   ("..tostring(Player:GetSpeed(FFXIV.MOVEMENT.FORWARD))..")"
	mimovb = tostring(Player:IsMoving(FFXIV.MOVEMENT.BACKWARD)).."   ("..tostring(Player:GetSpeed(FFXIV.MOVEMENT.BACKWARD))..")"
	mimovl = tostring(Player:IsMoving(FFXIV.MOVEMENT.LEFT)).."   ("..tostring(Player:GetSpeed(FFXIV.MOVEMENT.LEFT))..")"
	mimovr = tostring(Player:IsMoving(FFXIV.MOVEMENT.RIGHT)).."   ("..tostring(Player:GetSpeed(FFXIV.MOVEMENT.RIGHT))..")"
	
	-- AetheryteList
	local aefound = false
	local aelist = Player:GetAetheryteList()
	if (aelist ) then 
		local a = aelist[tonumber(aesel)]
		if a then
			aefound = true
			aeptr = string.format( "%x",tonumber(a.ptr))
			aeidx = a.id
			aename = a.name
			aeishp = tostring(a.ishomepoint)
			aeisfav = tostring(a.isfavpoint)
			aeterr = a.territory
			aeregion = tostring(a.region)
			aeisloc = tostring(a.islocalmap)
		end
	end
	if not aefound then
		aeptr = 0
		aeidx = 0
		aename = ""
		aeishp = 0
		aeisfav = 0
		aeterr = 0
		aeregion = 0
		aeisloc = 0
	end
	
	-- FateInfo
	local fafound = false
	local falist = MapObject:GetFateList()
	if ( falist ) then
		local f = falist[tonumber(faidx)]
		if ( f ) then		
			fafound = true
			faptr = f.ptr
			faid = f.id
			faname = f.name
			fadesc = f.description
			fastat = f.status
			facompl = f.completion
			fatype = f.type
			falvl = tostring ( f.level .." / max: ".. f.maxlevel)
			fapos = tostring ( math.floor(f.x * 10) / 10 .." / ".. math.floor(f.y * 10) / 10 .. " / " ..math.floor(f.z * 10) / 10)
			farad = f.radius 
			fdur = f.duration
		end
	end
	if (not fafound) then
		faptr = 0
		faid = 0
		faname = 0
		fadesc = 0
		fastat = 0
		facompl = 0
		fatype = 0
		falvl = 0
		fapos = 0
		farad = 0
		fdur = 0
	end
	fasynclvl = tostring(Player:GetSyncLevel())
	
	-- Fishinginfo
	fishstate = tostring(Player:GetFishingState())	
	fishcs = tostring(ActionList:CanCast(289,Player.id))
	fishbait = Player:GetBait()
	
	-- GatheringInfo
	local Glist = Player:GetGatherableSlotList()
	local gfound = false
	if ( Glist ) then
		local gitem = Glist[tonumber(gaidx)]
		if ( gitem ) then
			gfound = true
			gaptr = gitem.ptr
			gaid = gitem.id
			ganame = gitem.name
			gachan = gitem.chance			
			gahqchan = gitem.hqchance
			galevel = gitem.level
			gadesc = gitem.description
			gaindex = gitem.index
		end
	end
	if (not gfound ) then
		gaptr = 0
		gaid = 0
		ganame = 0
		gachan = 0
		gahqchan = 0
		galevel = 0
		gadesc = 0
		gaindex = 0
	end
	
	-- Respawn n Teleportinfo
	resState = tostring(Player.revivestate)
	
	-- CraftingInfo
	local synth = Crafting:SynthInfo()
	if ( synth )then
		crid = synth.itemid
		crst = synth.step
		crstm =synth.stepmax
		crdu = synth.durability
		crdum = synth.durabilitymax
		crpr = synth.progress
		crprm =synth.progressmax
		crqu = synth.quality
		crqum =synth.qualitymax
		crtext = synth.description
	else
		crid = 0
		crst = 0
		crstm =0
		crdu = 0
		crdum = 0
		crpr = 0
		crprm =0
		crqu = 0
		crqum =0
		crtext ="" 	
	end
	cropen = tostring(Crafting:IsCraftingLogOpen())
	
	-- PartyInfo
	local party = EntityList.myparty
	if ValidTable(party) then
		local member = party[tonumber(pamem)]
		if ( ValidTable(member) ) then
			pptr = member.ptr
			paname = member.name
			paid = member.id
			pareg = member.region
			pacid = member.mapid		
			palead = tostring(member.isleader)		
			papos = tostring ( math.floor(tonumber(member.pos.x)).." / ".. math.floor(member.pos.y ) .. " / " ..math.floor(member.pos.z))
			paonmesh = tostring(member.onmesh)
		end
	else
		pptr = 0
		paname = 0
		paid = 0
		pareg = 0
		pacid = 0
		papos = 0
		palead = false
		paonmesh = false
	end
	
	--Duty/PVP
	
	duty_selectwindow = tostring(ControlVisible("ContentsFinder"))
	duty_confirmenterwindow = tostring(ControlVisible("ContentsFinderConfirm"))
	duty_yesnowindow = tostring(ControlVisible("SelectYesno"))
	duty_IsLoading = tostring(Quest:IsLoading())
	duty_taskname = ml_task_hub:CurrentTask() ~= nil and ml_task_hub:CurrentTask().name or ""
	duty_taskstate = ml_task_hub:CurrentTask() ~= nil and ml_task_hub:CurrentTask().state or ""
	if (gBotMode == GetString("dutyMode")) then
		duty_taskencounter = ml_task_hub:RootTask() ~= nil and ml_task_hub:RootTask().encounterIndex or ""
	else
		duty_taskencounter = ""
	end
	
	
	-- QuestInfo
	local QList = Quest:GetQuestList()
	local quest,qid = nil
	if ( TableSize(QList) > 0 ) then
		qid,quest = next ( QList )
		local idx = 0
		while ( qid and quest ) do
			if ( idx == tonumber(QIindex) ) then
				break
			end
			idx = idx + 1
			qid,quest = next ( QList, qid )
		end	
	end
	
	if ( quest ) then
		QIID = quest.id
		QIName = quest.name
		QIStep = quest.step
		QuestI8A = quest.I8A
		QuestI8B = quest.I8B
		QuestI8C = quest.I8C
		QuestI8D = quest.I8D
		QuestI8E = quest.I8E
		QuestI8F = quest.I8F
		
		QuestI8AH = quest.I8AH
		QuestI8BH = quest.I8BH
		QuestI8CH = quest.I8CH
		QuestI8DH = quest.I8DH
		QuestI8EH = quest.I8EH
		QuestI8FH = quest.I8FH
		
		QuestI8AL = quest.I8AL
		QuestI8BL = quest.I8BL
		QuestI8CL = quest.I8CL
		QuestI8DL = quest.I8DL
		QuestI8EL = quest.I8EL
		QuestI8FL = quest.I8FL
		
		QuestI16A = quest.I16A
		QuestI16B = quest.I16B
		QuestI16C = quest.I16C
		
		QuestBit8 = tostring(quest.Bit8)
		QuestBit16 = tostring(quest.Bit16)
		QuestBit24 = tostring(quest.Bit24)
		QuestBit32 = tostring(quest.Bit32)
		QuestBit40 = tostring(quest.Bit40)
		QuestBit48 = tostring(quest.Bit48)
		
	else
		QIID = 0
		QIName = ""
		QIStep = 0
		QuestI8A = 0
		QuestI8B = 0
	end
	
	QIIsQADO = tostring(Quest:IsQuestAcceptDialogOpen())
	QIIsQRDO = tostring(Quest:IsQuestRewardDialogOpen())
	QIIsLoading = tostring(Quest:IsLoading())
	QIIsDialog = tostring(Quest:IsInDialog())
	
end

function Dev.DoTask()
	if (Dev.curTask) then
		Dev.curTask()
	end
end

function Dev.OnUpdateHandler( Event, ticks ) 	
	if ( ticks - Dev.lastticks > 250 ) then
		Dev.lastticks = ticks		
		if ( Dev.running ) then
			Dev.UpdateWindow()
			Dev.DoTask()
		end
	end
end

RegisterEventHandler("Module.Initalize",Dev.ModuleInit)
RegisterEventHandler("Gameloop.Update", Dev.OnUpdateHandler)
RegisterEventHandler("GUI.Item", Dev.HandleButtons )

RegisterEventHandler("Dev.Test1", Dev.Test1)
RegisterEventHandler("Dev.Test2", Dev.Test2)
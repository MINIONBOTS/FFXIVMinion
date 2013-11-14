Dev = { }
Dev.lastticks = 0
Dev.running = false
Dev.curTask = nil


function Dev.ModuleInit()
	GUI_NewWindow("Dev",400,50,250,430)
	GUI_NewField("Dev","Ptr","TargetPtr","TargetInfo")
	GUI_NewField("Dev","ObjectType","TargetGetType","TargetInfo")
	GUI_NewField("Dev","CharacterType","TargetGetNPCType","TargetInfo")
	GUI_NewField("Dev","ID","TargetID","TargetInfo")
	GUI_NewField("Dev","ContentID","TargetContentID","TargetInfo")
	GUI_NewField("Dev","Name","TargetName","TargetInfo")
	GUI_NewField("Dev","StatusBitfield","TStatus","TargetInfo")	
	GUI_NewField("Dev","Targetable","TTar","TargetInfo")
	GUI_NewField("Dev","Attackable","TAtk","TargetInfo")
	GUI_NewField("Dev","Aggressive","TAgg","TargetInfo")
	GUI_NewField("Dev","Friendly","TFri","TargetInfo")
	GUI_NewField("Dev","HasAggro","TAggro","TargetInfo")
	GUI_NewField("Dev","InCombat","Tincmb","TargetInfo")
	GUI_NewField("Dev","Aggropercentage","TAggroP","TargetInfo")
	GUI_NewField("Dev","distance","TargetDistance","TargetInfo")
	GUI_NewField("Dev","pos.x","TargetPosX","TargetInfo")
	GUI_NewField("Dev","pos.y","TargetPosY","TargetInfo")
	GUI_NewField("Dev","pos.z","TargetPosZ","TargetInfo")
	GUI_NewField("Dev","los","Tlos","TargetInfo")
	GUI_NewField("Dev","Heading","TargetHeading","TargetInfo")	
	GUI_NewField("Dev","Health","TargetHealth","TargetInfo")
	GUI_NewField("Dev","MP","TargetMP","TargetInfo")
	GUI_NewField("Dev","TP","TargetTP","TargetInfo")	
	GUI_NewField("Dev","TargetID","TTID","TargetInfo")
	GUI_NewField("Dev","level","TargetLevel","TargetInfo")
	GUI_NewField("Dev","Job","TargetProfession","TargetInfo")
	GUI_NewField("Dev","Can Gather","TargetCangather","TargetInfo")
	GUI_NewField("Dev","Belongs to FateID","TFate","TargetInfo")	
	GUI_NewField("Dev","CurrentAction","TAC","TargetInfo")
	GUI_NewField("Dev","LastAction","TLAC","TargetInfo")	
	
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
	RegisterEventHandler("Dev.Cast", Dev.Func)	
	sbSelSlot = 0		
	sbSelHotbar = "Actions"
	sbpendingcast = false
	
	GUI_NewComboBox("Dev","Inventory","invinv","InventoryInfo","0,1,2,3,1000,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500,10000,10001,10002,10003,10004,10005,10006,11000,12000,12001,12002");	
	GUI_NewNumeric("Dev","SlotNumber","invSelSlot","InventoryInfo","1","199");
	GUI_NewField("Dev","Ptr","invptr","InventoryInfo")
	GUI_NewField("Dev","ID","invid","InventoryInfo")
	GUI_NewField("Dev","Name/Desc","invname","InventoryInfo")
	GUI_NewField("Dev","InvType","invtype","InventoryInfo")
	GUI_NewField("Dev","InvSlot","invslot","InventoryInfo")
	GUI_NewField("Dev","Stackcount","invcount","InventoryInfo")
	GUI_NewField("Dev","MaxStackcount","invmaxcount","InventoryInfo")
	GUI_NewField("Dev","Condition","invcond","InventoryInfo")
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
	
	
	GUI_NewField("Dev","IsMoving","mimov","MovementInfo")
	GUI_NewField("Dev","Moves Forward","mimovf","MovementInfo")
	GUI_NewField("Dev","Moves Backward","mimovb","MovementInfo")
	GUI_NewField("Dev","Moves Left","mimovl","MovementInfo")
	GUI_NewField("Dev","Moves Right","mimovr","MovementInfo")
	GUI_NewButton("Dev","MoveForward","Dev.MoveF","MovementInfo")
	RegisterEventHandler("Dev.MoveF", Dev.Move)
	GUI_NewButton("Dev","MoveBackward","Dev.MoveB","MovementInfo")
	RegisterEventHandler("Dev.MoveB", Dev.Move)
	GUI_NewButton("Dev","MoveLeft","Dev.MoveL","MovementInfo")
	RegisterEventHandler("Dev.MoveL", Dev.Move)
	GUI_NewButton("Dev","MoveRight","Dev.MoveR","MovementInfo")
	RegisterEventHandler("Dev.MoveR", Dev.Move)	
	GUI_NewButton("Dev","Stop","Dev.MoveS","MovementInfo")
	RegisterEventHandler("Dev.MoveS", Dev.Move)		
	GUI_NewNumeric("Dev","Set Speed","mimovss","MovementInfo")
	GUI_NewComboBox("Dev","Set SpeedDirection","mimovssdir","MovementInfo","Forward,Backward,Left,Right");
	GUI_NewButton("Dev","Set Speed","Dev.SetSpeed","MovementInfo")
	RegisterEventHandler("Dev.SetSpeed", Dev.Move)	
	mimovss = 0
	mimovssdir = "Forward"
		
	
	-- Navigation functions
	GUI_NewField("Dev","X: ","tb_xPos","NavigationSystem")
	GUI_NewField("Dev","Y: ","tb_yPos","NavigationSystem")
	GUI_NewField("Dev","Z: ","tb_zPos","NavigationSystem")
	GUI_NewButton("Dev","GetCurrentPos","Dev.playerPosition","NavigationSystem")
	RegisterEventHandler("Dev.playerPosition", Dev.Move)	
	GUI_NewField("Dev","NavigateTo Result:","tb_nRes","NavigationSystem")
	GUI_NewButton("Dev","NavigateTo","Dev.naviTo","NavigationSystem")
	RegisterEventHandler("Dev.naviTo", Dev.Move)	
	GUI_NewButton("Dev","MoveToStraight","Dev.moveTo","NavigationSystem")
	RegisterEventHandler("Dev.moveTo", Dev.Move)	
	GUI_NewButton("Dev","Teleport","Dev.teleport","NavigationSystem")
	RegisterEventHandler("Dev.teleport", Dev.Move)	
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
	RegisterEventHandler("Dev.Sync", Dev.Func)
	faidx = 0
	fasynclvl = 0
	
	-- FishingInfo
	GUI_NewField("Dev","BaitItemID","fishbait","FishingInfo")
	GUI_NewField("Dev","SetBaitID","fishsbait","FishingInfo")
	GUI_NewButton("Dev","SetBaitID","Dev.Bait","FishingInfo")
	RegisterEventHandler("Dev.Bait", Dev.Func)
	GUI_NewField("Dev","FishingState","fishstate","FishingInfo")
	GUI_NewField("Dev","CanCast","fishcs","FishingInfo")
	GUI_NewButton("Dev","Start Fishing","Dev.Fish","FishingInfo")
	RegisterEventHandler("Dev.Fish", Dev.Func)
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
	RegisterEventHandler("Dev.Gather", Dev.Func)
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
	RegisterEventHandler("Dev.CraftLog", Dev.Func)
	GUI_NewButton("Dev","CraftSelectedItem","Dev.Craft","CraftingInfo")
	RegisterEventHandler("Dev.Craft", Dev.Func)
	
	-- Respawn_Teleportinfo
	GUI_NewField("Dev","RespawnState","resState","Respawn_Teleportinfo")
	GUI_NewButton("Dev","Respawn","Dev.Rezz","Respawn_Teleportinfo")
	RegisterEventHandler("Dev.Rezz", Dev.Func)
	
	--Partymember
	GUI_NewNumeric("Dev","Partymember","pamem","PartyInfo","0","10");
	GUI_NewField("Dev","Name","paname","PartyInfo")
	GUI_NewField("Dev","ID","paid","PartyInfo")
	GUI_NewField("Dev","Region","pareg","PartyInfo")
	GUI_NewField("Dev","MapID","pacid","PartyInfo")
	GUI_NewField("Dev","IsLeader","palead","PartyInfo")	
	GUI_NewField("Dev","OnMesh","paonmesh","PartyInfo")			
	GUI_NewField("Dev","Position","papos","PartyInfo")	
	pamem = 0
	
	-- General Functions
	GUI_NewButton("Dev","Interact with Target","Dev.Interact","General Functions")
	RegisterEventHandler("Dev.Interact", Dev.Func)		
	GUI_NewButton("Dev","Follow Target","Dev.Follow","General Functions")
	RegisterEventHandler("Dev.Follow", Dev.Func)
	GUI_NewNumeric("Dev","Sound","gsound","General Functions","0","71");
	GUI_NewButton("Dev","PlaySound","Dev.Sound","General Functions")
	RegisterEventHandler("Dev.Sound", Dev.Func)
	gsound = 0
	GUI_WindowVisible("Dev",false)
	
	GUI_NewButton("Dev","Test1button","Dev.Test1")
	GUI_NewButton("Dev","TOGGLE DEVMONITOR ON_OFF","Dev.Test2")
	GUI_SizeWindow("Dev",250,550)		
end

function Dev.Move( dir )
	if ( dir == "Dev.MoveF") then
		Player:Move(FFXIV.MOVEMENT.FORWARD)
	elseif ( dir == "Dev.MoveB") then
		Player:Move(FFXIV.MOVEMENT.BACKWARD)
	elseif ( dir == "Dev.MoveL") then
		Player:Move(FFXIV.MOVEMENT.LEFT)
	elseif ( dir == "Dev.MoveR") then
		Player:Move(FFXIV.MOVEMENT.RIGHT)
	elseif ( dir == "Dev.MoveS") then
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
	elseif ( dir == "Dev.playerPosition") then
			local p = Player.pos
			tb_xPos = tostring(p.x)
			tb_yPos = tostring(p.y)
			tb_zPos = tostring(p.z)
	elseif ( dir == "Dev.naviTo") then
		tb_nRes = tostring(Player:MoveTo(tonumber(tb_xPos),tonumber(tb_yPos),tonumber(tb_zPos)))
	elseif ( dir == "Dev.moveTo") then
		Player:MoveToStraight(tonumber(tb_xPos),tonumber(tb_yPos),tonumber(tb_zPos))
	elseif ( dir == "Dev.teleport") then
		Player:Teleport(tonumber(tb_xPos),tonumber(tb_yPos),tonumber(tb_zPos))
	end
end

function Dev.Func ( arg ) 
	if ( arg == "Dev.Interact") then
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

function Dev.Test1()
	d("Test1..")
	--local p = Player.pos
	--d(Player:GetGatherableSlotList())
	--local aa=MeshManager:AddVertex({x=p.x,y=p.z,z=p.y})
	--local bb=MeshManager:AddVertex({x=p.x+2,y=p.z,z=p.y+2})
	--local cc=MeshManager:AddVertex({x=p.x-2,y=p.z,z=p.y+1})	
	--d(MeshManager:AddTriangle({a=aa,b=bb,c=cc}))
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

function Dev.Test2()
	Dev.running = not Dev.running
	if ( not Dev.running) then Dev.curTask = nil end
	d(Dev.running)
end
			
function Dev.UpdateWindow()
	mytarget = Player:GetTarget() 
	if (mytarget  ~= nil) then	
		TargetPtr = string.format( "%x",tonumber(mytarget.ptr ))
		TargetID = mytarget.id
		TargetGetType = mytarget.type
		TargetGetNPCType = mytarget.chartype
		TargetName = mytarget.name
		TargetContentID = mytarget.contentid
		TStatus = mytarget.status--string.format( "%x",tonumber(mytarget.status ))
		TTar = tostring(mytarget.targetable)
		TAggro = tostring(mytarget.aggro)
		TAggroP = mytarget.aggropercentage
		TAtk = tostring(mytarget.attackable)
		TAgg = tostring(mytarget.aggressive)
		TFri = tostring(mytarget.friendly)
		Tincmb = tostring(mytarget.incombat)
		TargetDistance = (math.floor(mytarget.distance * 10) / 10)
		Tlos = tostring(mytarget.los)
		TargetPosX = (math.floor(mytarget.pos.x * 10) / 10)
		TargetPosY = (math.floor(mytarget.pos.y * 10) / 10)
		TargetPosZ = (math.floor(mytarget.pos.z * 10) / 10)
		TargetHeading = (math.floor(mytarget.pos.h * 10) / 10)
		TargetHealth = tostring(mytarget.hp.current.." / "..mytarget.hp.max.." / "..mytarget.hp.percent.."%")	
		TargetMP = tostring(mytarget.mp.current.." / "..mytarget.mp.max.." / "..mytarget.mp.percent.."%")	
		TargetTP = mytarget.tp
		TTID = tostring(mytarget.targetid)
		TargetLevel = mytarget.level
		TargetProfession = mytarget.job
		TargetCangather = tostring(mytarget.cangather)
		TFate = mytarget.fateid or 0
		TAC = mytarget.action
		TLAC = mytarget.lastaction
		tfaid = mytarget.fateid
	else
		local el = EntityList("nearest,onmesh,gatherable")
		if ( el ) then
			i,mytarget = next (el)
			if ( i and mytarget ) then
				--Player:SetTarget(i)
				TargetPtr = string.format( "%x",tonumber(mytarget.ptr ))
				TargetID = mytarget.id
				TargetContentID = mytarget.contentid
				TargetGetType = mytarget.type
				TargetGetNPCType = mytarget.chartype
				TargetName = mytarget.name
				TStatus = mytarget.status--string.format( "%x",tonumber(mytarget.status ))
				TTar = tostring(mytarget.targetable)
				TAggro = tostring(mytarget.aggro)
				TAggroP = mytarget.aggropercentage
				TAtk = tostring(mytarget.attackable)
				TAgg = tostring(mytarget.aggressive)
				TFri = tostring(mytarget.friendly)
				Tincmb = tostring(mytarget.incombat)
				TargetDistance = (math.floor(mytarget.distance * 10) / 10)
				Tlos = tostring ( mytarget.los)
				TargetPosX = (math.floor(mytarget.pos.x * 10) / 10)
				TargetPosY = (math.floor(mytarget.pos.y * 10) / 10)
				TargetPosZ = (math.floor(mytarget.pos.z * 10) / 10)
				TargetHeading = (math.floor(mytarget.pos.h * 10) / 10)
				TargetHealth = tostring(mytarget.hp.current.." / "..mytarget.hp.max.." / "..mytarget.hp.percent.."%")	
				TargetMP = tostring(mytarget.mp.current.." / "..mytarget.mp.max.." / "..mytarget.mp.percent.."%")	
				TargetTP = mytarget.tp
				TTID = tostring(mytarget.targetid)
				TargetLevel = mytarget.level
				TargetProfession = mytarget.job
				TargetCangather = tostring(mytarget.cangather)
				TFate = mytarget.fateid or 0
				TAC = mytarget.action
				TLAC = mytarget.lastaction
			end
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
	
	
	--Inventory/ItemList
	local inv = Inventory("type="..invinv)
	local found = false
	if ( inv ) then
		local item = inv[tonumber(invSelSlot)]
		if ( item ) then
			found = true
			invptr = string.format( "%x",tonumber(item.ptr ))
			invid = item.id
			invname = item.name
			invtype = item.type
			invslot = item.slot
			invcount = item.count
			invmaxcount = item.max
			invcond = item.condition
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
	
	local Plist = EntityList.myparty
	local pfound = false
	local i,member = next (Plist)	
	if (i and member ) then
		local member = Plist[tonumber(pamem)]
		if ( member) then
		pfound=true
		paname = member.name
		paid = member.id
		pareg = member.region
		pacid = member.mapid		
		palead = tostring(member.isleader)		
		papos = tostring ( math.floor(tonumber(member.pos.x)).." / ".. math.floor(member.pos.y ) .. " / " ..math.floor(member.pos.z))
		paonmesh = tostring(member.onmesh)
		end
	end
	if not pfound then
		paname = 0
		paid = 0
		pareg = 0
		pacid = 0
		papos = 0
		palead = false
		paonmesh = false
	end
	
end

function Dev.DoTask()
	if (Dev.curTask) then
		Dev.curTask()
	end
end

function Dev.OnUpdateHandler( Event, ticks ) 	
	if ( ticks - Dev.lastticks > 500 ) then
		Dev.lastticks = ticks		
		if ( Dev.running ) then
			Dev.UpdateWindow()
			
			Dev.DoTask()
		end
	end
end

RegisterEventHandler("Module.Initalize",Dev.ModuleInit)
RegisterEventHandler("Gameloop.Update", Dev.OnUpdateHandler)
RegisterEventHandler("Dev.Test1", Dev.Test1)
RegisterEventHandler("Dev.Test2", Dev.Test2)
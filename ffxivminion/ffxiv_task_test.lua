ffxiv_task_test = inheritsFrom(ml_task)
ffxiv_task_test.lastTick = 0

function ffxiv_task_test.Create()
    local newinst = inheritsFrom(ffxiv_task_test)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "TEST"
	newinst.taskCreated = false
	newinst.moveCreated = false
   
    return newinst
end

c_gotomaptest = inheritsFrom( ml_cause )
e_gotomaptest = inheritsFrom( ml_effect )
function c_gotomaptest:evaluate()	
	local mapID = tonumber(gTestMapID)
	if (Player.localmapid ~= mapID and not ml_task_hub:ThisTask().taskCreated) then
		return true
	end
end
function e_gotomaptest:execute()
	local mapID = tonumber(gTestMapID)
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = mapID
	ml_task_hub:CurrentTask():AddSubTask(task)
	ml_task_hub:ThisTask().taskCreated = true
end

c_gotopostest = inheritsFrom( ml_cause )
e_gotopostest = inheritsFrom( ml_effect )
e_gotopostest.pos = nil
function c_gotopostest:evaluate()	
	local mapID = tonumber(gTestMapID)
	if (Player.localmapid == mapID and not ml_task_hub:ThisTask().moveCreated) then
		local ppos = shallowcopy(Player.pos)
		local pos = {}
		pos.x = tonumber(gTestMapX)
		pos.y = tonumber(gTestMapY)
		pos.z = tonumber(gTestMapZ)
		if (Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z) > 10) then
			e_gotopostest.pos = pos
			return true
		end
	end
	return false
end
function e_gotopostest:execute()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.remainMounted = true
	newTask.pos = e_gotopostest.pos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
	ml_task_hub:ThisTask().moveCreated = true
end

function ffxiv_task_test:Init()
	local ke_startMapTest = ml_element:create( "GoToMapTest", c_gotomaptest, e_gotomaptest, 20 )
    self:add(ke_startMapTest, self.process_elements)
	
	local ke_startMoveTest = ml_element:create( "GoToPosTest", c_gotopostest, e_gotopostest, 15 )
    self:add(ke_startMoveTest, self.process_elements)
end

function ffxiv_task_test.UIInit()
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end
    ffxivminion.Windows.Test = { id = "Test", Name = "NavTest", x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Test)

	local winName = "NavTest"
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	
    GUI_NewField(winName, "MapID:", "gTestMapID","NavTest")
	GUI_NewField(winName, "X:", "gTestMapX","NavTest")
	GUI_NewField(winName, "Y:", "gTestMapY","NavTest")
	GUI_NewField(winName, "Z:", "gTestMapZ","NavTest")
	GUI_NewButton(winName, "Get Current Position", "ffxiv_navtestGetPosition", "NavTest")
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,"NavTest")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

function ffxiv_task_test.OnUpdate( event, tickcount )
	if (gBotRunning == "1") then
		if (TimeSince(ffxiv_task_test.lastTick) >= 1000) then
			ffxiv_task_test.lastTick = Now()
			
			local tasks = {}
			local level = 1
			
			if (ml_task_hub:RootTask()) then
				local task = ml_task_hub:RootTask()
				currTask = nil
				while (task ~= nil) do
					tasks[level] = task.name
					currTask = task
					task = task.subtask
					level = level + 10
				end
			end
			
			local winName = "NavTest"
			GUI_DeleteGroup(winName,"Tasks")
			if (TableSize(tasks) > 0) then
				for k,v in spairs(tasks) do
					GUI_NewButton(winName, tostring(k).."("..v..")", "TestViewTask"..tostring(k), "Tasks")
				end
				GUI_UnFoldGroup(winName,"Tasks")
			end

			ffxivminion.SizeWindow(winName)
			GUI_RefreshWindow(winName)
		end
	end
end

function ffxiv_task_test.GetCurrentPosition()
	local mapid = Player.localmapid
	local pos = Player.pos
	
	gTestMapX = pos.x
	gTestMapY = pos.y
	gTestMapZ = pos.z
	gTestMapID = mapid
end

function ffxiv_task_test.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"ffxiv_navtest") ~= nil ) then
		if (Button == "ffxiv_navtestGetPosition") then
			ffxiv_task_test.GetCurrentPosition()
		end
	end
end

RegisterEventHandler("GUI.Item",ffxiv_task_test.HandleButtons)
RegisterEventHandler("Gameloop.Update",ffxiv_task_test.OnUpdate)
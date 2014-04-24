-- initializes the questmanager which is included in minionlib and handles the executionlogic of quests/steps
ffxiv_quest_manager = {}
ffxiv_quest_manager.profilepath = GetStartupPath() .. [[\LuaMods\ffxivminion\QuestManagerProfiles\]];


function ffxiv_quest_manager.ModuleInit( ) 
	ml_quest_mgr.ModuleInit("FFXIVMINION",ffxiv_quest_manager.profilepath ) -- from minionlib/ml_quest_mgr.lua
	
end
RegisterEventHandler("Module.Initalize",ffxiv_quest_manager.ModuleInit) -- from minionlib/ml_quest_mgr.lua



-- RunQuestProfile-Task for example how to run the quest-step-script-tasks ;)
ffxiv_task_quest = inheritsFrom(ml_task)
ffxiv_task_quest.name = "QuestMode"

function ffxiv_task_quest.Create()
	local newinst = inheritsFrom(ffxiv_task_quest)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
	newinst.currentQuestPrio = 0
	newinst.currentStepPrio = 0
	newinst.currentScript = nil

	
    return newinst
end

function ffxiv_task_quest:Init()

end

function ffxiv_task_quest:Process()
		
	if ( self.currentScript == nil ) then
		local t = ml_quest_mgr.GetNextIncompleteQuest()
		if ( TableSize(t) == 3) then
			self.currentQuestPrio = t[1]
			self.currentStepPrio = t[2]
			self.currentScript = t[3]		
			
		else
			ml_log("No QuestProfile loaded or Profile completed!")			
		end
	else
		
		if ( self.currentScript.completed == true ) then
			d("Script finished: "..tostring(self.currentScript.name))
			
			-- Set this step to "Finished" in our character's questprofile progress			-- 									
			ml_quest_mgr.SetQuestData( self.currentQuestPrio, self.currentStepPrio, nil, "done", "1" )
			
			-- TODO: Saving the Quest progress logic has to be done from here too...just call  ml_quest_mgr.SaveProfile() to save it
			

			
			self.currentScript = nil
		else
			--Run quest-Task
			ml_task_hub:CurrentTask():AddSubTask(self.currentScript)
		end		
	end
end

function ffxiv_task_quest:task_complete_eval()
	d("ffxiv_task_quest:task_complete_eval->")
	return false
end
function ffxiv_task_quest:task_complete_execute()
    d("ffxiv_task_quest:task_complete_execute->")
end

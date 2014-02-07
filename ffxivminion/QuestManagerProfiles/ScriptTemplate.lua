-- This script template contains the basic functions you have to implement when creating your own scripts.
script = inheritsFrom( ml_task )
script.name = "ScriptTemplate"
script.Data = {}

--******************
-- ml_quest_mgr Functions
--******************
function script:UIInit( identifier )
	-- You need to create the ScriptUI Elements exactly like you see here, the "event" needs to start with "tostring(identifier).." and the group needs to be GetString("questStepDetails")
	GUI_NewCheckbox(ml_quest_mgr.stepwindow.name,"ScriptBox",tostring(identifier).."_Checkbox",GetString("questStepDetails"))	
	GUI_NewField(ml_quest_mgr.stepwindow.name,"ScriptField",tostring(identifier).."_Field",GetString("questStepDetails"))
	GUI_NewButton(ml_quest_mgr.stepwindow.name,"ScriptButton",tostring(identifier).."_Button",GetString("questStepDetails"))
	GUI_NewNumeric(ml_quest_mgr.stepwindow.name,"ScriptButton",tostring(identifier).."_Numeric",GetString("questStepDetails"),"0","999");
		
end

function script:SetData( identifier, tData )
	-- Save the data in our script-"instance" aka global variables and set the UI elements
	if ( identifier and tData ) then		
		--d("script:SetData: "..tostring(identifier))
				
		self.Data = tData
		
		-- Update the script UI (make sure the Data assigning to a _G is NOT nil! else crashboooombang!)
		if ( self.Data["_Field"] ) then _G[tostring(identifier).."_Field"] = self.Data["_Field"] end
		if ( self.Data["_Checkbox"] ) then _G[tostring(identifier).."_Checkbox"] = self.Data["_Checkbox"] end
		if ( self.Data["_Numeric"] ) then _G[tostring(identifier).."_Numeric"] = self.Data["_Numeric"] end
	end
end

function script:EventHandler( identifier, event )
	-- for extended UI event handling, gets called when a scriptUI element is pressed
	
end

--******************
-- ml_Task Functions
--******************
script.valid = true
script.completed = false
script.subtask = nil
script.process_elements = {}
script.overwatch_elements = {} 

function script:Init()
    -- Add Cause&Effects here, like in a normal Task for example mc_ai_combat.lua
	
end
function script:Process()
	-- Having this Process() function defined, overwrites the usage of any Cause&Effects defined in the Init(), you can basicly just execute code in here
	
end

function script:task_complete_eval()
	ml_log("script:Complete?->")
	
	return ml_log(false)
end
function script:task_complete_execute()
   self.completed = true
end


return script
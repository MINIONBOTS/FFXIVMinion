script = inheritsFrom( ml_task )
script.name = "KillSpecificEnemiesAtPos"
script.Data = {}

--******************
-- ml_quest_mgr Functions
--******************
function script:UIInit( identifier )
	GUI_NewCheckbox(ml_quest_mgr.stepwindow.name,"ScriptBox",tostring(identifier).."_Checkbox",GetString("questStepDetails"))	
	GUI_NewField(ml_quest_mgr.stepwindow.name,"ScriptField",tostring(identifier).."_Field",GetString("questStepDetails"))
	GUI_NewButton(ml_quest_mgr.stepwindow.name,"SriptButton",tostring(identifier).."_Button",GetString("questStepDetails"))	
	GUI_NewNumeric(ml_quest_mgr.stepwindow.name,"ScriptButton",tostring(identifier).."_Numeric",GetString("questStepDetails"),"0","999");
	
end

function script:SetData( identifier, tData )
	if ( identifier and tData ) then		
		--d("script:SetData: "..tostring(identifier))
		
		-- Save data in our script-"instance"
		self.Data = tData
		
		-- Update the script UI (make sure the Data assigning to a _G is NOT nil! else crashboooombang!)
		if ( self.Data["_Field"] ) then _G[tostring(identifier).."_Field"] = self.Data["_Field"] end
		if ( self.Data["_Checkbox"] ) then _G[tostring(identifier).."_Checkbox"] = self.Data["_Checkbox"] end
		if ( self.Data["_Numeric"] ) then _G[tostring(identifier).."_Numeric"] = self.Data["_Numeric"] end
	end
end

function script:EventHandler( identifier, event )
	
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
    ml_log("script_Init->")
	
end
function script:Process()	
	d(script.name.." Process()")
	self.completed = true
end
function script:task_complete_eval()
	ml_log("script:Complete?->")
	
	return ml_log(false)
end
function script:task_complete_execute()
   self.completed = true
end


return script
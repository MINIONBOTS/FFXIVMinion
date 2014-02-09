-- CNE functions
ml_cne_hub = {}
ml_cne_hub.effect_queue = {}
ml_cne_hub.execution_queue = {}

function ml_cne_hub.clear_queue()
	ml_cne_hub.effect_queue = {}
	ml_cne_hub.execution_queue = {}
end

function ml_cne_hub.eval_elements(elementList)
	for k, elem in pairs( elementList ) do
        if (gLogCNE == "1") then
            ml_debug( "Evaluating:" .. tostring( elem.name ) )
        end
		elem.eval = elem:evaluate()
    if (gLogCNE == "1") then
            ml_debug( elem.name .. " evaluation result:" .. tostring( elem.eval ) )
        end
	end
end

-- Queue effect. depending on the priority the effect will be executed
function ml_cne_hub.queue_effect( effect )
	if safe_isA( ml_effect, effect ) then
		ml_cne_hub.effect_queue[ tostring( effect ) ] = effect
	else
		ml_error( "effect is not wt_effect based" )
	end
end

-- add a effect to be executed
function ml_cne_hub.queue_to_execute( )
	local highestPriority = 0
	-- Get the hightest priority in the effect_queue
	for k, effect in pairs( ml_cne_hub.effect_queue ) do
		if ( highestPriority < effect.priority ) then
				highestPriority = effect.priority
		end
	end
	--ml_debug( "Highest Priority:" .. highestPriority )
	-- All effect in the execution que with a priority lower then the hightest in the effect cue are removed
	if ( highestPriority > 0 ) then
		for k, effect in pairs( ml_cne_hub.execution_queue ) do
			if( effect.priority < highestPriority ) then
                if (gLogCNE == "1") then
                    ml_debug( "Removing:"..effect.name .. "(P:"..effect.priority..")" )
                end
				effect:interrupt()
				ml_cne_hub.execution_queue[ k ] = nil
			end
		end
		-- All effects with the hightest priority will be added to the execution que
		for k, effect in pairs( ml_cne_hub.effect_queue ) do
			if ( highestPriority == effect.priority ) then
                if (gLogCNE == "1") then
                    ml_debug( "Scheduling:" .. effect.name .. "(P:"..effect.priority..")" )
                end
				effect.execution_count = 0
				ml_cne_hub.execution_queue[ tostring( effect ) ] = effect
			end
		end
	end
end

function ml_cne_hub.execute()
	local executed = false
	for k, effect in pairs( ml_cne_hub.execution_queue ) do
		if ( effect:isvalid() and effect:SafetyCheck() ) then
			effect.execution_count = effect.execution_count + 1
			ml_global_information.LastEffect = effect
			effect.last_execution = ml_global_information.Now
			effect.first_execution = 0					
			if ( gFFXIVMinionEffect ~= nil ) then
			gFFXIVMinionEffect = self.name.."."..effect.name
			GUI_SetStatusBar(effect.name)
			end
            if (gLogCNE == "1") then
                ml_debug( "execute:" .. effect.name .. " (P:"..effect.priority..")" )
            end
			effect:execute()
			executed = true
		else
			--ml_debug( "removing:" .. effect.name .. " KEY:" ..k .. " (P:"..effect.priority..")" )
			ml_cne_hub.execution_queue[ k ] = nil
		end
	end
	return executed
end
-- effect trigger actions

--require 'ml_misc_OO'

ml_effect = inheritsFrom( nil )

ml_effect.name = "ml_effect"

ml_effect.priorities = {
	normal = 1,
	high = 1000,
	interrupt = 10000
}

ml_effect.types = {
	once = 1,
	repeating = 2
}

ml_effect.throttle = 0
ml_effect.last_execution = 0
ml_effect.delay = 0
ml_effect.first_execution = 0
ml_effect.type = ml_effect.types.once
ml_effect.priority = ml_effect.priorities.normal
ml_effect.execution_count = 0
ml_effect.max_execution_count = 0
ml_effect.usesAbility = false

-- Checked by the ml_core_controller before the effect is executed , failing the check will not remove the effect from the queue
function ml_effect:SafetyCheck()

	-- If the effect is flagged to use an ability, we check that we are not casting, interacting or the global cooldown is in effect.
	-- If the effect priority is interrupt, we will ignore that fact that we are casting already.
	--ml_debug( "safety_check" )
	if ( self.usesAbility == true ) then
			--if ( ml_global_information:GetGCD() > 0 or ml_global_information.isInteracting() == true or ( ml_global_information.isCasting() and self.priority < ml_effect.priorities.interrupt ) ) then
				--ml_debug( "SafetyCheck false, GCD not ready" )
				--return false
			--end
	end
	
	-- delays the execution, so that some actions performed are able to wait for the game to react proper	
	if ( self.delay > 0 ) then
		if ( self.first_execution == 0 ) then		
			self.first_execution = ml_global_information.Now			
			return false
		else			
			return ( ml_global_information.Now - self.first_execution ) > self.delay
		end		
	end

	if ( self.throttle > 0 ) then
		local Elapsed = ( ml_global_information.Now - self.last_execution )
		--ml_debug( "Elapsed: ".. tostring( Elapsed ) .. " - " .. tostring( self.throttle ) )
		return Elapsed >  self.throttle
	end
	
	return true
end

-- called when the effect should take place.
function ml_effect:execute()

end

-- called before execute is called. the execution of the effect depends
-- on the result of isvalid(). If false the effect is not be executed and removed from the queue
-- the effect should clean up if the result of isvalid() will be false.
function ml_effect:isvalid()

	--ml_debug( "isvalid" )

	if ( self.type == ml_effect.types.once and self.execution_count > 0 ) then
			return false
	end

	if ( self.type == ml_effect.types.repeating and self.max_execution_count > 0 and self.execution_count > self.max_execution_count ) then
			return false
	end

	return true
end

-- called when the effect is interrupted by another effect of a higher priority.
-- the effect can clean up here.
function ml_effect:interrupt()

end

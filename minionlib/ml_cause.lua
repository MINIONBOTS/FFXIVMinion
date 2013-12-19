-- the cause is evalutated by the the kelement
-- it dictates if the associated effect will be executed

--require 'ml_misc_OO'

ml_cause  =  inheritsFrom( nil )
ml_cause.throttle = 0 -- Make sure to use this ONLY for C&E's that change the State on a successfull Check in the Effect! 
ml_cause.last_execution = 0	

function ml_cause:SafetyCheck()
	if ( self.throttle > 0 ) then
		if (ml_global_information.Now - self.last_execution > self.throttle) then	
			self.last_execution = ml_global_information.Now
			return true
		end
		return false
	end	
	return true
end

function ml_cause:evaluate()
	return false
end


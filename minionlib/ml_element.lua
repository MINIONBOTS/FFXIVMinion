-- The knowledge element consists of:
-- cause: is evaluated and should be true or false
-- effect: is executed if the cause is true
-- priority : defines the priority of the effect. used to determine what effects will be executed

--require 'ml_misc_OO'
--require 'ml_cause'
--require 'ml_effect'
--require 'ml_core_controller'

ml_element =  inheritsFrom( nil )
ml_element.cause = inheritsFrom( ml_cause )
ml_element.effect = inheritsFrom( ml_effect )

ml_element.name = "ml_element"

function ml_element:evaluate()
	if ( type( self.cause ) == "function" ) then
		if ( self:cause() == true ) then
			 ml_cne_hub.queue_effect( self.effect )
			 return true
		end
	elseif ( self.cause:SafetyCheck() and self.cause:evaluate() == true ) then
			 ml_cne_hub.queue_effect( self.effect )
			 return true
	end
	return false
end

function ml_element:create( name, cause, effect, priority )
        local newinst = inheritsFrom( ml_element )
        newinst.name = name
        newinst.cause = cause
        newinst.effect = effect
		newinst.effect.name = name
        newinst.effect.priority = priority == nil and ml_effect.priorities.normal or priority
        newinst.eval = false
        newinst.lastExec = 0
        return newinst
end

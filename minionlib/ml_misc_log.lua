-- Log and output functions

--require 'gui\\ml_logwindow'
 
-- DumpTable : recursive print the passed table
function DT( atable, intend )
		if ( intend == nil ) then intend = 1 end

		if ( atable ~= nil and type( atable )=="table" ) then
			for ItemField, FieldContent in pairs( atable ) do
				if type( FieldContent ) == "table" then
					ml_debug( string.rep( "  ", intend ) .. ItemField .. " = " .. tostring( FieldContent ) .. " (" .. type( FieldContent ) .. ")" )
					DT( FieldContent, intend + 1 );
				else
					ml_debug( string.rep( "  ", intend ) .. ItemField .. " = " .. tostring( FieldContent ) .. " (" .. type( FieldContent ) .. ")" )
	  			end
			end
		end
end

function ml_debug( OutString )
	if ( gEnableLog ~= nil and gEnableLog == "1" ) then
		d( tostring( OutString ) )		
	end
end

function ml_error( text )
	GUI_ToggleConsole(true)
	d( "**ERROR**: " .. tostring( text ) )
end

ml_logstring = ""
function ml_log( arg )	
	if (type( arg ) == "boolean" and arg == true) then		
		ml_logstring = ml_logstring.."("..tostring(arg)..")::"
		return true
	elseif (type( arg ) == "boolean" and arg == false) then		
		ml_logstring = ml_logstring.."("..tostring(arg)..")::"
		return false
	elseif (type( arg ) == "string" and arg == "Running") then		
		ml_logstring = ml_logstring.."("..arg..")::"
		return "Running"
	else	
		ml_logstring = ml_logstring..arg
	end
	--d( debug.traceback())	
end

function ml_GetTraceString()
	local t = ml_logstring
	ml_logstring = ""
	return t
end
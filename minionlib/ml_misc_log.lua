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

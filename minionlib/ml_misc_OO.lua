-- All object oriented stuff goes here


function safe_isA( baseClass , Class )
		if ( baseClass ~= nil and Class ~= nil and  type( Class ) == "table" and Class.isa ~= nil and type( Class.isa ) == "function"  and Class:isa( baseClass ) ) then
			return true
		else
			return false
		end
end

function inheritsFrom( baseClass )

    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class.Create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if nil ~= baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    -- Implementation of additional OO properties starts here --

    -- Return the class object of the instance
    function new_class:class()
        return new_class
    end

    -- Return the super class object of the instance
    function new_class:superClass()
        return baseClass
    end

    -- Return true if the caller is an instance of theClass
    function new_class:isa( theClass )
        local b_isa = false

        local cur_class = new_class

        while ( nil ~= cur_class ) and ( false == b_isa ) do
            if cur_class == theClass then
                b_isa = true
            else
                cur_class = cur_class:superClass()
            end
        end

        return b_isa
    end

	-- Inherit variables
	if (baseClass) then
		for name,value in pairs(baseClass) do
			if (type(value) == "table" or
				type(value) == "string" or
				type(value) == "number" or
				type(value) == "boolean" )
			then
				new_class[name] = value
			end
		end
	end
	
    return new_class
end


function TableSize( T )
	
	if ( T == nil or type( T ) ~= "table" ) then
		return 0
	end
	
	local count = 0
	
	k, v  = next( T )
	while ( k ~= nil ) do			
		count = count + 1
		k, v  = next( T, k )
	end

	return count
end

function mergeT( A, B)

	local sB = TableSize( B )
	local StartB = 1
	local Result = {}

	for iB = 1, sB,1 do
	  if ( A[1] == B[iB] ) then
		StartB = iB
		break
	  end
	end

	for iR = StartB , sB, 1 do
	 Result[iR-StartB+1] = B[iR]
	end

	return Result

end

function wtround( num, idp )
  local mult = 10^( idp or 0 )
  return math.floor( num * mult + 0.5 ) / mult
end

function deepcopy( object )
    local lookup_table = {}
    local function _copy( object )
        if type( object ) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs( object ) do
            new_table[_copy( index )] = _copy( value )
        end
        return setmetatable(new_table, getmetatable( object ) )
    end
    return _copy( object )
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if tostring(value) == tostring(element) then
      return true
    end
  end
  return false
end

function Distance3D( x, y, z, x1, y1, z1 )
	dx = x1-x
	dy = y1-y
	dz = z1-z
	return math.sqrt( math.pow( dx, 2 ) + math.pow( dy, 2 ) + math.pow( dz, 2 ) )
end

function Distance2D( x, y, x1, y1)
	dx = x1-x
	dy = y1-y
	return math.sqrt( math.pow( dx, 2 ) + math.pow( dy, 2 ))
end

function toboolean ( input)
	if ( input ~= nil )then
		if (tostring(input) == "true") then
			return 1
		end
	end
	return 0
end

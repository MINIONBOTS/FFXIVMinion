ml_node = inheritsFrom(nil)

function ml_node:Create()
    local node = inheritsFrom(ml_node)
    node.id = 0
    node.neighbors = {}
	
	return node
end

function ml_node:Neighbors()
    return self.neighbors
end

function ml_node:AddNeighbor(id, neighbor)
    if (not self:GetNeighbor(id)) then
        self.neighbors[id] = neighbor
    end
end

function ml_node:GetNeighbor(id)    
    return self.neighbors[id]
end

function ml_node:GetClosestNeighborPos(origin, id)
    local neighbor = self:GetNeighbor(id)
	if (ValidTable(neighbor)) then
		--if the neighbor is valid, check all of our gates and see which gate is closest
		local gates = neighbor.gates
		if (TableSize(gates) > 1) then
			local bestPos = nil
			local bestDist = 9999999
			for id, posTable in pairs(gates) do
				local dist = Distance3D(origin.x, origin.y, origin.z, posTable.x, posTable.y, posTable.z)
				if (dist < bestDist) then
					bestPos = posTable
					bestDist = dist
				end
			end
			
			if (ValidTable(bestPos)) then
				return bestPos
			end
		elseif (TableSize(gates == 1)) then
			return gates[1]
		end
    end
    
    return nil
end

--OVERRIDE IN GAME MODULE IF NECESSARY.
function ml_node:DistanceTo(id)
	local neighbor = self:GetNeighbor(id)
    if (neighbor) then
		local cost = neighbor.cost or 5
        return cost
    end
    
    return nil
end


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

function ml_node:AddNeighbor(id, posTable)
    if (not self:GetNeighbor(id)) then
        self.neighbors[id] = posTable
    end
end

function ml_node:GetNeighbor(id)    
    return self.neighbors[id]
end

function ml_node:GetClosestNeighborPos(origin, id)
    local neighborPos = self:GetNeighbor(id)
	if (ValidTable(neighborPos)) then
		if (TableSize(neighborPos) > 1) then
			local bestPos = nil
			local bestDist = 9999999
			for id, posTable in pairs(neighborPos) do
				local dist = Distance3D(origin.x, origin.y, origin.z, posTable.x, posTable.y, posTable.z)
				if (dist < bestDist) then
					bestPos = posTable
					bestDist = dist
				end
			end
			
			if (ValidTable(bestPos)) then
				return bestPos
			end
		elseif (TableSize(neighborPos == 1)) then
			return neighborPos[1]
		end
    end
    
    return nil
end

function ml_node:DistanceTo(id)
    if (self:GetNeighbor(id)) then
        return 1
    end
    
    return nil
end


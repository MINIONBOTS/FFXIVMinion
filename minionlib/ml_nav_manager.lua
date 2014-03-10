ml_nav_manager = {}
ml_nav_manager.nodes = {}
ml_nav_manager.currPath = {}
ml_nav_manager.currID = 0
ml_nav_manager.destID = 0

-- API Functions

-- this is probably the only function that should be called for path finding
function ml_nav_manager.GetNextPathPos(currPos, currID, destID)
    if (not ValidTable(ml_nav_manager.currPath) or
		currID ~= ml_nav_manager.currID or
		destID ~= ml_nav_manager.destID) 
	then
        ml_nav_manager.SetNavPath(currID, destID)
    end
	
	if (ValidTable(ml_nav_manager.currPath)) then
		ml_nav_manager.currID = currID
		ml_nav_manager.destID = destID
		
		for index, node in pairsByKeys(ml_nav_manager.currPath) do
			if (node.id == currID) then
				local nextNode = ml_nav_manager.currPath[index + 1]
				if (ValidTable(nextNode)) then
					local pos = node:GetClosestNeighborPos(currPos,nextNode.id)
					if (ValidTable(pos)) then
						return pos
					end
				else
					ml_debug("Already at last node in path")
					return -1
				end
			end
		end
	end
end

function ml_nav_manager.AddNode(node)
    if (not ml_nav_manager.nodes[node.id]) then
        ml_nav_manager.nodes[node.id] = node
    end
end


-- Internal functions
function ml_nav_manager.GetNode(id)
    return ml_nav_manager.nodes[id]
end

function ml_nav_manager.SetNavPath(currID, destID)
    local currNode = ml_nav_manager.GetNode(currID)
    local destNode = ml_nav_manager.GetNode(destID)
    
    ml_nav_manager.currPath = ml_nav_manager.GetPath(currNode, destNode)
end

function ml_nav_manager.GetPath(source, dest)
    local nodes = ml_nav_manager.nodes
	--Create a closed and open set
	local open = {}
	local closed = {}
 
	local data = {}
	for id, node in pairs(nodes) do
		data[id] = {
			distance = math.huge,
			previous = nil
		}
		
		open[id] = true
	end
 
	--The source node has a distance of 0, and sources in the open set
	data[source.id].distance = 0
 
	while TableSize(open) > 0 do
		--pick the nearest open node
		local best = nil
		for id, _ in pairs(open) do
			if not best or data[id].distance < data[best.id].distance then
				best = ml_nav_manager.GetNode(id)
			end
		end
 
		--at the dest - stop looking
		if best == dest then break end
 
		--all nodes traversed - dest not found! No connection between source and dest
		if not best then return end
 
		--calculate a new score for each neighbour
		for id, neighbor in pairs(best:Neighbors()) do
			if open[id] then
				local newdist = data[best.id].distance + best:DistanceTo(id)
				if newdist < data[id].distance then
					data[id].distance = newdist
					data[id].previous = best
				end
			end
		end
 
		--move the node to the closed set
		open[best.id] = nil
	end
 
	--walk backwards to reconstruct the path
	local path = {}
	local at = dest
	while at ~= nil do
		table.insert(path, 1, at)
		at = data[at.id].previous
	end
 
	return path
end
ffxiv_map_nav = {}
ffxiv_map_nav.data = nil
ffxiv_map_nav.initialized = false

function ffxiv_map_nav.IsAetheryte(id)
	if not id then return false end
	local row = FFXIVLib.API.Map.GetAetheryteById(id)
	if not row then return false end
	return row.IsAetheryte == true
end

function ffxiv_map_nav.IsAethernet(id)
	if not id then return false end
	local row = FFXIVLib.API.Map.GetAetheryteById(id)
	if not row then return false end
	return row.IsAetheryte ~= true
end

function ffxiv_map_nav.SetupNavNodes()
	if not ffxiv_map_nav.data then return false end
	ml_nav_manager.nodes = {}
	ml_nav_manager._pathCache = {}
	local nodeCount = 0
	local edgeCount = 0
	local emptyEdge = 0
	local addedIds = {}
	local referencedIds = {}
	for id, neighbors in pairs(ffxiv_map_nav.data) do
		local node = ml_node:Create()
		if (ValidTable(node)) then
			node.id = id
			addedIds[id] = true
			for nid, posTable in pairs(neighbors) do
				if type(posTable) == "table" and #posTable > 0 then
					node:AddNeighbor(nid, posTable)
					edgeCount = edgeCount + 1
					referencedIds[nid] = true
				else
					emptyEdge = emptyEdge + 1
				end
			end
			ml_nav_manager.AddNode(node)
			nodeCount = nodeCount + 1
		end
	end
	-- Create stub nodes for dead-end maps that are referenced as neighbors
	-- but have no outgoing edges (e.g. inn rooms like map 177).
	local stubCount = 0
	for nid, _ in pairs(referencedIds) do
		if not addedIds[nid] then
			local stub = ml_node:Create()
			if ValidTable(stub) then
				stub.id = nid
				ml_nav_manager.AddNode(stub)
				stubCount = stubCount + 1
				nodeCount = nodeCount + 1
			end
		end
	end
	navd("[Nav] SetupNavNodes: nodes=" .. nodeCount .. " edges=" .. edgeCount .. " emptySkipped=" .. emptyEdge .. " stubs=" .. stubCount)
	return true
end

function ffxiv_map_nav.EnsureNavGraph()
	if ffxiv_map_nav.initialized then return true end
	if FFXIVData_RequestNavDiscovery then FFXIVData_RequestNavDiscovery() end
	if ml_global_information and ml_global_information.EnsureMeshDefaults then
		ml_global_information.EnsureMeshDefaults()
	end
	if not FFXIVLib or not FFXIVLib.API or not FFXIVLib.API.Nav
		or not FFXIVLib.API.Nav.BuildNavData
	then
		return false
	end

	local data = FFXIVLib.API.Nav.BuildNavData()
	if type(data) ~= "table" then return false end
	ffxiv_map_nav.data = data
	if not ffxiv_map_nav.SetupNavNodes() then return false end
	ffxiv_map_nav.initialized = true
	return true
end

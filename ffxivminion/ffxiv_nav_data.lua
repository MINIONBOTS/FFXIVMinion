ffxiv_map_nav = {}
ffxiv_map_nav.data = FFXIVLib.API.Nav.BuildNavData()

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
	ml_nav_manager.nodes = {}
	ml_nav_manager._pathCache = {}
	local nodeCount = 0
	local edgeCount = 0
	local emptyEdge = 0
	for id, neighbors in pairs(ffxiv_map_nav.data) do
		local node = ml_node:Create()
		if (ValidTable(node)) then
			node.id = id
			for nid, posTable in pairs(neighbors) do
				if type(posTable) == "table" and #posTable > 0 then
					node:AddNeighbor(nid, posTable)
					edgeCount = edgeCount + 1
				else
					emptyEdge = emptyEdge + 1
				end
			end
			ml_nav_manager.AddNode(node)
			nodeCount = nodeCount + 1
		end
	end
	d("[Nav] SetupNavNodes: nodes=" .. nodeCount .. " edges=" .. edgeCount .. " emptySkipped=" .. emptyEdge)
end

ffxiv_map_nav.SetupNavNodes()

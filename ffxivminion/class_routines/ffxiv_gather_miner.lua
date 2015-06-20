ffxiv_gather_miner = {}
ffxiv_gather_miner.range = 3
ffxiv_gather_miner.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_gather_miner.info"
local options, e = persistence.load(ffxiv_gather_miner.optionsPath)
if (options) then
	ffxiv_gather_miner.options = options
end
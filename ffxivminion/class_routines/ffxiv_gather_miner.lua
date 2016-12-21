ffxiv_gather_miner = {}
ffxiv_gather_miner.range = 3
ffxiv_gather_miner.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_gather_miner.info"
if (not FileExists(ffxiv_gather_miner.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gPotionHP = 50,
		gFleeMP = 0,
		gRestMP = 30,
		gPotionMP = 0,
		gFleeHP = 35,
		gUseSprint = "1",
		gRestHP = 75,
	}
	persistence.store(ffxiv_gather_miner.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_gather_miner.optionsPath)
if (options) then
	ffxiv_gather_miner.options = options
end
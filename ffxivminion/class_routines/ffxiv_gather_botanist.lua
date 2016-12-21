ffxiv_gather_botanist = {}
ffxiv_gather_botanist.range = 3
ffxiv_gather_botanist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_gather_botanist.info"
if (not FileExists(ffxiv_gather_botanist.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gPotionHP = 50,
		gFleeMP = 0,
		gRestMP = 30,
		gPotionMP = 0,
		gFleeHP = 35,
		gUseSprint = "`",
		gRestHP = 75,
	}
	persistence.store(ffxiv_gather_botanist.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_gather_botanist.optionsPath)
if (options) then
	ffxiv_gather_botanist.options = options
end
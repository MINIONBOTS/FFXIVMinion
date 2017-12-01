ffxiv_combat_marauder = {}
ffxiv_combat_marauder.range = 2
ffxiv_combat_marauder.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_marauder.info"
if (not FileExists(ffxiv_combat_marauder.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 70,
		gRestMP = 0,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 10,
		gFleeMP = 0,
		gUseSprint = "0",
	}
	persistence.store(ffxiv_combat_marauder.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_marauder.optionsPath)
if (options) then
	ffxiv_combat_marauder.options = options
end

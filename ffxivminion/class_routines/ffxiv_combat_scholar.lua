ffxiv_combat_scholar = {}
ffxiv_combat_scholar.range = 24
ffxiv_combat_scholar.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_scholar.info"
if (not FileExists(ffxiv_combat_scholar.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 30,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 35,
		gFleeMP = 0,
		gUseSprint = "1",
	}
	persistence.store(ffxiv_combat_scholar.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_scholar.optionsPath)
if (options) then
	ffxiv_combat_scholar.options = options
end

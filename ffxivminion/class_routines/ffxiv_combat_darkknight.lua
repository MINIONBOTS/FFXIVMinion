ffxiv_combat_darkknight = {}
ffxiv_combat_darkknight.range = 2
ffxiv_combat_darkknight.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_darkknight.info"
if (not FileExists(ffxiv_combat_darkknight.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 70,
		gRestMP = 0,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 25,
		gFleeMP = 0,
		gUseSprint = "0",
	}
	persistence.store(ffxiv_combat_darkknight.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_darkknight.optionsPath)
if (options) then
	ffxiv_combat_darkknight.options = options
end
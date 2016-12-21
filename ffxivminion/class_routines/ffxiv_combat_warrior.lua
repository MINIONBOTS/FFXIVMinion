ffxiv_combat_warrior = {}
ffxiv_combat_warrior.range = 2
ffxiv_combat_warrior.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_warrior.info"
if (not FileExists(ffxiv_combat_warrior.optionsPath)) then
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
	persistence.store(ffxiv_combat_warrior.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_warrior.optionsPath)
if (options) then
	ffxiv_combat_warrior.options = options
end
ffxiv_combat_gladiator = {}
ffxiv_combat_gladiator.range = 2
ffxiv_combat_gladiator.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_gladiator.info"
if (not FileExists(ffxiv_combat_gladiator.optionsPath)) then
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
	persistence.store(ffxiv_combat_gladiator.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_gladiator.optionsPath)
if (options) then
	ffxiv_combat_gladiator.options = options
end

ffxiv_combat_monk = {}
ffxiv_combat_monk.range = 2
ffxiv_combat_monk.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_monk.info"
if (not FileExists(ffxiv_combat_monk.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 0,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 35,
		gFleeMP = 0,
		gUseSprint = "0",
	}
	persistence.store(ffxiv_combat_monk.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_monk.optionsPath)
if (options) then
	ffxiv_combat_monk.options = options
end

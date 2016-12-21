ffxiv_combat_paladin = {}
ffxiv_combat_paladin.range = 2
ffxiv_combat_paladin.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_paladin.info"
if (not FileExists(ffxiv_combat_paladin.optionsPath)) then
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
	persistence.store(ffxiv_combat_paladin.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_paladin.optionsPath)
if (options) then
	ffxiv_combat_paladin.options = options
end

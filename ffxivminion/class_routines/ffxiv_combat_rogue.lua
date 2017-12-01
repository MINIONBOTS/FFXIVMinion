ffxiv_combat_rogue = {}
ffxiv_combat_rogue.range = 2
ffxiv_combat_rogue.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_rogue.info"
if (not FileExists(ffxiv_combat_rogue.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 0,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 15,
		gFleeMP = 0,
		gUseSprint = "0",
	}
	persistence.store(ffxiv_combat_rogue.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_rogue.optionsPath)
if (options) then
	ffxiv_combat_rogue.options = options
end

ffxiv_combat_archer = {}
ffxiv_combat_archer.range = 24
ffxiv_combat_archer.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_archer.info"
if (not FileExists(ffxiv_combat_archer.optionsPath)) then
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
	persistence.store(ffxiv_combat_archer.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_archer.optionsPath)
if (options) then
	ffxiv_combat_archer.options = options
end
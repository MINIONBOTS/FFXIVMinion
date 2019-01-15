ffxiv_combat_bluemage = {}
ffxiv_combat_bluemage.range = 24
ffxiv_combat_bluemage.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_bluemage.info"
if (not FileExists(ffxiv_combat_bluemage.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 0,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 35,
		gFleeMP = 0,
		gUseSprint = "1",
	}
	persistence.store(ffxiv_combat_bluemage.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_bluemage.optionsPath)
if (options) then
	ffxiv_combat_bluemage.options = options
end
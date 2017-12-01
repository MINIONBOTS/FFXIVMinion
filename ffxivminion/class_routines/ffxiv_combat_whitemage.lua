ffxiv_combat_whitemage = {}
ffxiv_combat_whitemage.range = 24
ffxiv_combat_whitemage.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_whitemage.info"
if (not FileExists(ffxiv_combat_whitemage.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 30,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 20,
		gFleeMP = 0,
		gUseSprint = "1",
	}
	persistence.store(ffxiv_combat_whitemage.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_whitemage.optionsPath)
if (options) then
	ffxiv_combat_whitemage.options = options
end
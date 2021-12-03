ffxiv_combat_sage = {}
ffxiv_combat_sage.range = 24
ffxiv_combat_sage.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_sage.info"
if (not FileExists(ffxiv_combat_sage.optionsPath)) then
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
	persistence.store(ffxiv_combat_sage.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_sage.optionsPath)
if (options) then
	ffxiv_combat_sage.options = options
end

ffxiv_combat_bard = {}
ffxiv_combat_bard.range = 24
ffxiv_combat_bard.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_bard.info"
if (not FileExists(ffxiv_combat_bard.optionsPath)) then
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
	persistence.store(ffxiv_combat_bard.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_bard.optionsPath)
if (options) then
	ffxiv_combat_bard.options = options
end


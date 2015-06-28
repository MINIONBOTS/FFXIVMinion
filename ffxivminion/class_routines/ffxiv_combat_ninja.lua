ffxiv_combat_ninja = {}
ffxiv_combat_ninja.range = 2
ffxiv_combat_ninja.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_ninja.info"
if (not FileExists(ffxiv_combat_ninja.optionsPath)) then
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
	persistence.store(ffxiv_combat_ninja.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_ninja.optionsPath)
if (options) then
	ffxiv_combat_ninja.options = options
end


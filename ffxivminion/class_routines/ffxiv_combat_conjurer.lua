ffxiv_combat_conjurer = {}
ffxiv_combat_conjurer.range = 24
ffxiv_combat_conjurer.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_conjurer.info"
if (not FileExists(ffxiv_combat_conjurer.optionsPath)) then
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
	persistence.store(ffxiv_combat_conjurer.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_conjurer.optionsPath)
if (options) then
	ffxiv_combat_conjurer.options = options
end
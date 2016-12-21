ffxiv_combat_summoner = {}
ffxiv_combat_summoner.range = 24
ffxiv_combat_summoner.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_summoner.info"
if (not FileExists(ffxiv_combat_summoner.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 30,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 35,
		gFleeMP = 0,
		gUseSprint = "1",
	}
	persistence.store(ffxiv_combat_summoner.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_summoner.optionsPath)
if (options) then
	ffxiv_combat_summoner.options = options
end
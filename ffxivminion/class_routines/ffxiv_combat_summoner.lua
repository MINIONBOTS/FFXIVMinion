ffxiv_combat_summoner = {}
ffxiv_combat_summoner.range = 24
ffxiv_combat_summoner.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_summoner.info"
local options, e = persistence.load(ffxiv_combat_summoner.optionsPath)
if (options) then
	ffxiv_combat_summoner.options = options
end
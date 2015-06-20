ffxiv_combat_lancer = {}
ffxiv_combat_lancer.range = 2
ffxiv_combat_lancer.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_lancer.info"
local options, e = persistence.load(ffxiv_combat_lancer.optionsPath)
if (options) then
	ffxiv_combat_lancer.options = options
end

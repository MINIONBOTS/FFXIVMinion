ffxiv_combat_marauder = {}
ffxiv_combat_marauder.range = 2
ffxiv_combat_marauder.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_marauder.info"
local options, e = persistence.load(ffxiv_combat_marauder.optionsPath)
if (options) then
	ffxiv_combat_marauder.options = options
end

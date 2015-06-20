ffxiv_combat_arcanist = {}
ffxiv_combat_arcanist.range = 24
ffxiv_combat_arcanist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_arcanist.info"
local options, e = persistence.load(ffxiv_combat_arcanist.optionsPath)
if (options) then
	ffxiv_combat_arcanist.options = options
end
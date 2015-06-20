ffxiv_combat_darkknight = {}
ffxiv_combat_darkknight.range = 2
ffxiv_combat_darkknight.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_darkknight.info"
local options, e = persistence.load(ffxiv_combat_darkknight.optionsPath)
if (options) then
	ffxiv_combat_darkknight.options = options
end
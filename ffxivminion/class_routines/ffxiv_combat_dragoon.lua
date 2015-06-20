ffxiv_combat_dragoon = {}
ffxiv_combat_dragoon.range = 2
ffxiv_combat_dragoon.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_dragoon.info"
local options, e = persistence.load(ffxiv_combat_dragoon.optionsPath)
if (options) then
	ffxiv_combat_dragoon.options = options
end

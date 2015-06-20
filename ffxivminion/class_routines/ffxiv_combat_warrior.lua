ffxiv_combat_warrior = {}
ffxiv_combat_warrior.range = 2
ffxiv_combat_warrior.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_warrior.info"
local options, e = persistence.load(ffxiv_combat_warrior.optionsPath)
if (options) then
	ffxiv_combat_warrior.options = options
end
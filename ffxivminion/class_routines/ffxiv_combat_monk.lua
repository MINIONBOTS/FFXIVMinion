ffxiv_combat_monk = {}
ffxiv_combat_monk.range = 2
ffxiv_combat_monk.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_monk.info"
local options, e = persistence.load(ffxiv_combat_monk.optionsPath)
if (options) then
	ffxiv_combat_monk.options = options
end

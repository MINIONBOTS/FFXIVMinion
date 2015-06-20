ffxiv_combat_thaumaturge = {}
ffxiv_combat_thaumaturge.range = 24
ffxiv_combat_thaumaturge.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_thaumaturge.info"
local options, e = persistence.load(ffxiv_combat_thaumaturge.optionsPath)
if (options) then
	ffxiv_combat_thaumaturge.options = options
end
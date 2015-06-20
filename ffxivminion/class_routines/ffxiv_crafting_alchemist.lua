ffxiv_crafting_alchemist = {}
ffxiv_crafting_alchemist.range = 3
ffxiv_crafting_alchemist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_alchemist.info"
local options, e = persistence.load(ffxiv_crafting_alchemist.optionsPath)
if (options) then
	ffxiv_crafting_alchemist.options = options
end
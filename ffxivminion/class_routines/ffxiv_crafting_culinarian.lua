ffxiv_crafting_culinarian = {}
ffxiv_crafting_culinarian.range = 3
ffxiv_crafting_culinarian.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_culinarian.info"
local options, e = persistence.load(ffxiv_crafting_culinarian.optionsPath)
if (options) then
	ffxiv_crafting_culinarian.options = options
end
ffxiv_crafting_armorer = {}
ffxiv_crafting_armorer.range = 3
ffxiv_crafting_armorer.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_armorer.info"
local options, e = persistence.load(ffxiv_crafting_armorer.optionsPath)
if (options) then
	ffxiv_crafting_armorer.options = options
end
ffxiv_crafting_leatherworker = {}
ffxiv_crafting_leatherworker.range = 3
ffxiv_crafting_leatherworker.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_leatherworker.info"
local options, e = persistence.load(ffxiv_crafting_leatherworker.optionsPath)
if (options) then
	ffxiv_crafting_leatherworker.options = options
end
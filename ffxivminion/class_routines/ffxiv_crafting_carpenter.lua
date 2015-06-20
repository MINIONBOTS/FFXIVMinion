ffxiv_crafting_carpenter = {}
ffxiv_crafting_carpenter.range = 3
ffxiv_crafting_carpenter.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_carpenter.info"
local options, e = persistence.load(ffxiv_crafting_carpenter.optionsPath)
if (options) then
	ffxiv_crafting_carpenter.options = options
end

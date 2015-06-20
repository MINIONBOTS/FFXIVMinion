ffxiv_crafting_weaver = {}
ffxiv_crafting_weaver.range = 3
ffxiv_crafting_weaver.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_weaver.info"
local options, e = persistence.load(ffxiv_crafting_weaver.optionsPath)
if (options) then
	ffxiv_crafting_weaver.options = options
end
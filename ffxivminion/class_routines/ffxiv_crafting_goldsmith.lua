ffxiv_crafting_goldsmith = {}
ffxiv_crafting_goldsmith.range = 3
ffxiv_crafting_goldsmith.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_goldsmith.info"
local options, e = persistence.load(ffxiv_crafting_goldsmith.optionsPath)
if (options) then
	ffxiv_crafting_goldsmith.options = options
end
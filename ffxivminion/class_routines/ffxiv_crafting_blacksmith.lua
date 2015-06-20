ffxiv_crafting_blacksmith = {}
ffxiv_crafting_blacksmith.range = 3
ffxiv_crafting_blacksmith.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_blacksmith.info"
local options, e = persistence.load(ffxiv_crafting_blacksmith.optionsPath)
if (options) then
	ffxiv_crafting_blacksmith.options = options
end
ffxiv_combat_scholar = {}
ffxiv_combat_scholar.range = 24
ffxiv_combat_scholar.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_scholar.info"
local options, e = persistence.load(ffxiv_combat_scholar.optionsPath)
if (options) then
	ffxiv_combat_scholar.options = options
end

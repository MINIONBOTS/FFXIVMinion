ffxiv_combat_bard = {}
ffxiv_combat_bard.range = 24
ffxiv_combat_bard.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_bard.info"
local options, e = persistence.load(ffxiv_combat_bard.optionsPath)
if (options) then
	ffxiv_combat_bard.options = options
end


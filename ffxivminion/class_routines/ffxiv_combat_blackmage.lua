ffxiv_combat_blackmage = {}
ffxiv_combat_blackmage.range = 24
ffxiv_combat_blackmage.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_blackmage.info"
local options, e = persistence.load(ffxiv_combat_blackmage.optionsPath)
if (options) then
	ffxiv_combat_blackmage.options = options
end
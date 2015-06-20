ffxiv_combat_machinist = {}
ffxiv_combat_machinist.range = 24
ffxiv_combat_machinist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_machinist.info"
local options, e = persistence.load(ffxiv_combat_machinist.optionsPath)
if (options) then
	ffxiv_combat_machinist.options = options
end
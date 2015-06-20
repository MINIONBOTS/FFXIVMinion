ffxiv_combat_rogue = {}
ffxiv_combat_rogue.range = 2
ffxiv_combat_rogue.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_rogue.info"
local options, e = persistence.load(ffxiv_combat_rogue.optionsPath)
if (options) then
	ffxiv_combat_rogue.options = options
end

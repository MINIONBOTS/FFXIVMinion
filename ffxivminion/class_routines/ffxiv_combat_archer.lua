ffxiv_combat_archer = {}
ffxiv_combat_archer.range = 24
ffxiv_combat_archer.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_archer.info"
local options, e = persistence.load(ffxiv_combat_archer.optionsPath)
if (options) then
	ffxiv_combat_archer.options = options
end
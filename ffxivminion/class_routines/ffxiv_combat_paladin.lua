ffxiv_combat_paladin = {}
ffxiv_combat_paladin.range = 2
ffxiv_combat_paladin.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_paladin.info"
local options, e = persistence.load(ffxiv_combat_paladin.optionsPath)
if (options) then
	ffxiv_combat_paladin.options = options
end

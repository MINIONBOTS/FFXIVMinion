ffxiv_combat_pugilist = {}
ffxiv_combat_pugilist.range = 2
ffxiv_combat_pugilist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_pugilist.info"
local options,e = persistence.load(ffxiv_combat_pugilist.optionsPath)
if (options) then
	ffxiv_combat_pugilist.options = options
end

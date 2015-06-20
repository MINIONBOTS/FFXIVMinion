ffxiv_combat_ninja = {}
ffxiv_combat_ninja.range = 2
ffxiv_combat_ninja.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_ninja.info"
local options, e = persistence.load(ffxiv_combat_ninja.optionsPath)
if (options) then
	ffxiv_combat_ninja.options = options
end


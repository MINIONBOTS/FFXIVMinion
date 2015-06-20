ffxiv_combat_conjurer = {}
ffxiv_combat_conjurer.range = 24
ffxiv_combat_conjurer.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_conjurer.info"
local options, e = persistence.load(ffxiv_combat_conjurer.optionsPath)
if (options) then
	ffxiv_combat_conjurer.options = options
end
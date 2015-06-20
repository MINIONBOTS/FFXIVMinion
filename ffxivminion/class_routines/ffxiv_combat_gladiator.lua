ffxiv_combat_gladiator = {}
ffxiv_combat_gladiator.range = 2
ffxiv_combat_gladiator.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_gladiator.info"
local options, e = persistence.load(ffxiv_combat_gladiator.optionsPath)
if (options) then
	ffxiv_combat_gladiator.options = options
end

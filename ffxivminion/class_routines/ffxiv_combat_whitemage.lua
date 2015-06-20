ffxiv_combat_whitemage = {}
ffxiv_combat_whitemage.range = 24
ffxiv_combat_whitemage.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_whitemage.info"
local options, e = persistence.load(ffxiv_combat_whitemage.optionsPath)
if (options) then
	ffxiv_combat_whitemage.options = options
end
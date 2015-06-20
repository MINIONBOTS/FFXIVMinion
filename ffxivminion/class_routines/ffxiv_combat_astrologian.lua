ffxiv_combat_astrologian = {}
ffxiv_combat_astrologian.range = 24
ffxiv_combat_astrologian.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_astrologian.info"
local options, e = persistence.load(ffxiv_combat_astrologian.optionsPath)
if (options) then
	ffxiv_combat_astrologian.options = options
end
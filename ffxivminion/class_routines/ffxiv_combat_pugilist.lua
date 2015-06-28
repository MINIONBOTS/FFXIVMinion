ffxiv_combat_pugilist = {}
ffxiv_combat_pugilist.range = 2
ffxiv_combat_pugilist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_pugilist.info"
if (not FileExists(ffxiv_combat_pugilist.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 0,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 35,
		gFleeMP = 0,
		gUseSprint = "0",
	}
	persistence.store(ffxiv_combat_pugilist.optionsPath,defaults)
end
local options,e = persistence.load(ffxiv_combat_pugilist.optionsPath)
if (options) then
	ffxiv_combat_pugilist.options = options
end

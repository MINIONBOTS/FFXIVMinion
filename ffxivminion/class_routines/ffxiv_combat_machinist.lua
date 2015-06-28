ffxiv_combat_machinist = {}
ffxiv_combat_machinist.range = 24
ffxiv_combat_machinist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_machinist.info"
if (not FileExists(ffxiv_combat_machinist.optionsPath)) then
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
	persistence.store(ffxiv_combat_machinist.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_machinist.optionsPath)
if (options) then
	ffxiv_combat_machinist.options = options
end
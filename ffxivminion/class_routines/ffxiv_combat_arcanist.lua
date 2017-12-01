ffxiv_combat_arcanist = {}
ffxiv_combat_arcanist.range = 24
ffxiv_combat_arcanist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_arcanist.info"
if (not FileExists(ffxiv_combat_arcanist.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 75,
		gRestMP = 30,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 20,
		gFleeMP = 0,
		gUseSprint = "1",
	}
	persistence.store(ffxiv_combat_arcanist.optionsPath,defaults)
end

local options, e = persistence.load(ffxiv_combat_arcanist.optionsPath)
if (options) then
	ffxiv_combat_arcanist.options = options
end
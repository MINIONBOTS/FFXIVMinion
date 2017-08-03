ffxiv_combat_redmage = {}
ffxiv_combat_redmage.range = 2
ffxiv_combat_redmage.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_redmage.info"
if (not FileExists(ffxiv_combat_redmage.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gRestHP = 50,
		gRestMP = 30,
		gPotionHP = 50,
		gPotionMP = 0,
		gFleeHP = 35,
		gFleeMP = 0,
		gUseSprint = "1",
	}
	persistence.store(ffxiv_combat_redmage.optionsPath,defaults)
end

local options, e = persistence.load(ffxiv_combat_redmage.optionsPath)
if (options) then
	ffxiv_combat_redmage.options = options
end
ffxiv_combat_viper= {}
ffxiv_combat_viper.range = 2
ffxiv_combat_viper.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_combat_viper.info"
if (not FileExists(ffxiv_combat_viper.optionsPath)) then
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
	persistence.store(ffxiv_combat_viper.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_combat_viper.optionsPath)
if (options) then
	ffxiv_combat_viper.options = options
end

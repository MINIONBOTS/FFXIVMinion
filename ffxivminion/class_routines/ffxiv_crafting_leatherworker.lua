ffxiv_crafting_leatherworker = {}
ffxiv_crafting_leatherworker.range = 3
ffxiv_crafting_leatherworker.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_leatherworker.info"
if (not FileExists(ffxiv_crafting_leatherworker.optionsPath)) then
	local defaults = {}
	defaults.settings = {
		gPotionHP = 50,
		gFleeMP = 0,
		gRestMP = 30,
		gPotionMP = 0,
		gFleeHP = 35,
		gUseSprint = "1",
		gRestHP = 75,
	}
	persistence.store(ffxiv_crafting_leatherworker.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_crafting_leatherworker.optionsPath)
if (options) then
	ffxiv_crafting_leatherworker.options = options
end
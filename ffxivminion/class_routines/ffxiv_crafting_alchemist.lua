ffxiv_crafting_alchemist = {}
ffxiv_crafting_alchemist.range = 3
ffxiv_crafting_alchemist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_alchemist.info"
if (not FileExists(ffxiv_crafting_alchemist.optionsPath)) then
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
	persistence.store(ffxiv_crafting_alchemist.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_crafting_alchemist.optionsPath)
if (options) then
	ffxiv_crafting_alchemist.options = options
end
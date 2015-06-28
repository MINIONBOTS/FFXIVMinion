ffxiv_crafting_culinarian = {}
ffxiv_crafting_culinarian.range = 3
ffxiv_crafting_culinarian.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_culinarian.info"
if (not FileExists(ffxiv_crafting_culinarian.optionsPath)) then
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
	persistence.store(ffxiv_crafting_culinarian.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_crafting_culinarian.optionsPath)
if (options) then
	ffxiv_crafting_culinarian.options = options
end
ffxiv_crafting_goldsmith = {}
ffxiv_crafting_goldsmith.range = 3
ffxiv_crafting_goldsmith.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_goldsmith.info"
if (not FileExists(ffxiv_crafting_goldsmith.optionsPath)) then
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
	persistence.store(ffxiv_crafting_goldsmith.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_crafting_goldsmith.optionsPath)
if (options) then
	ffxiv_crafting_goldsmith.options = options
end
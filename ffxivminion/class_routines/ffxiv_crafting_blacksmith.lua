ffxiv_crafting_blacksmith = {}
ffxiv_crafting_blacksmith.range = 3
ffxiv_crafting_blacksmith.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_blacksmith.info"
if (not FileExists(ffxiv_crafting_blacksmith.optionsPath)) then
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
	persistence.store(ffxiv_crafting_blacksmith.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_crafting_blacksmith.optionsPath)
if (options) then
	ffxiv_crafting_blacksmith.options = options
end
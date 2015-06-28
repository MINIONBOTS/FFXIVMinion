ffxiv_crafting_weaver = {}
ffxiv_crafting_weaver.range = 3
ffxiv_crafting_weaver.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_crafting_weaver.info"
if (not FileExists(ffxiv_crafting_weaver.optionsPath)) then
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
	persistence.store(ffxiv_crafting_weaver.optionsPath,defaults)
end
local options, e = persistence.load(ffxiv_crafting_weaver.optionsPath)
if (options) then
	ffxiv_crafting_weaver.options = options
end
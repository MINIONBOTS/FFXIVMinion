ffxiv_gather_fisher = {}
ffxiv_gather_fisher.range = 3
ffxiv_gather_fisher.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_gather_fisher.info"
local options, e = persistence.load(ffxiv_gather_fisher.optionsPath)
if (options) then
	ffxiv_gather_fisher.options = options
end
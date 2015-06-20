ffxiv_gather_botanist = {}
ffxiv_gather_botanist.range = 3
ffxiv_gather_botanist.optionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."ffxiv_gather_botanist.info"
local options, e = persistence.load(ffxiv_gather_botanist.optionsPath)
if (options) then
	ffxiv_gather_botanist.options = options
end
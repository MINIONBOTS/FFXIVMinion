-- Small compatibility shims for static datasets now owned by FFXIVLib.
-- Indexed reads stay compatible without rebuilding the backing tables at startup.

chatcodes = setmetatable({}, {
	__index = function(_, code)
		if FFXIVLib and FFXIVLib.API and FFXIVLib.API.Chat then
			return FFXIVLib.API.Chat.GetCode(code)
		end
		return nil
	end,
})


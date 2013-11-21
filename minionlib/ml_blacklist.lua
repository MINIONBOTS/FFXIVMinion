--ml_blacklist is a general framework for creating and using blacklists 
ml_blacklist = {}
ml_blacklist.blacklist = {}
ml_blacklist.lastClearTime = 0

-- checks for temporarily blacklisted entries and removed them if time is up
function ml_blacklist.ClearBlacklists()
    if (os.difftime(os.time(), ml_blacklist.lastClearTime) > 1) then
        ml_blacklist.lastClearTime = os.time()
    
        for name, blacklist in pairs(ml_blacklist.blacklist) do
            for entry, time in pairs (blacklist) do
                if time ~= true and os.difftime(os.time(), time) > 0 then
                    ml_blacklist.blacklist[name].entry = nil
                end
            end
        end
    end
end

-- creates a new blacklist and assigns clearThrottle as the timer to check 
-- for temp entries to remove
function ml_blacklist.CreateBlacklist(blacklistName)
    ml_blacklist.blacklist[blacklistName] = {}
end

-- checks ALL blacklists to see if entryName exists
-- use this ONLY if you're sure your blacklists have unique types
function ml_blacklist.IsBlacklisted(entryName)
	for name, blacklist in pairs(ml_blacklist.blacklist) do
		for entry, time in pairs (blacklist) do
			if entry == entryName then
				return true
			end
		end
	end
	
	return false
end

-- checks only the named blacklist to see if entryName exists
function ml_blacklist.CheckBlacklistEntry(blacklistName, entryName)
	local blacklist = ml_blacklist.blacklist[blacklistName]
	if blacklist[entryName] then
		return true
	end
end

-- adds a new entry to the named blacklist for the given time duration
-- if time == -1 then the entry is permanent for the duration of the session
function ml_blacklist.AddBlacklistEntry(blacklistName, entryName, time)
	local blacklist = ml_blacklist.blacklist[blacklistName]
	blacklist[entryName] = time
end

function ml_blacklist.GetExcludeString(blacklistName)
    local excludeString = ""
	local blacklist = ml_blacklist.blacklist[blacklistName]
    for entry, time in pairs(blacklist) do
        excludeString = excludeString .. entry .. ","
    end
    
    if (excludeString ~= "") then
        -- strip off trailing comma
        return excludeString:sub(1,excludeString:len() - 1) 
    else
        return nil
    end
end
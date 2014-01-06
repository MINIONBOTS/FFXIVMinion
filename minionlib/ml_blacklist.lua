--ml_blacklist is a general framework for creating and using blacklists 
ml_blacklist = {}
ml_blacklist.blacklist = {}
ml_blacklist.lastClearTime = 0

-- checks for temporarily blacklisted entries and removed them if time is up
function ml_blacklist.ClearBlacklists()
    if (TimeSince(ml_blacklist.lastClearTime) > 500) then
        ml_blacklist.lastClearTime = ml_global_information.Now
    
        for name, blacklist in pairs(ml_blacklist.blacklist) do
            for id, entry in pairs (blacklist) do
                if entry.time ~= true and TimeSince(entry.time) > 0 then
                    ml_blacklist.DeleteEntry(name, id)
                end
            end
        end
    end
end

-- creates a new blacklist and assigns clearThrottle as the timer to check 
-- for temp entries to remove
function ml_blacklist.CreateBlacklist(blacklistName)
    ml_blacklist.blacklist[blacklistName] = {}
    ml_blacklist_mgr.RefreshNames()
end

-- checks ALL blacklists to see if entryName exists
-- use this ONLY if you're sure your blacklists have unique types
function ml_blacklist.IsBlacklisted(entryName)
	for name, blacklist in pairs(ml_blacklist.blacklist) do
		for id, entry in pairs (blacklist) do
			if entry.name == entryName then
				return true
			end
		end
	end
	
	return false
end

-- checks only the named blacklist to see if entryName exists
function ml_blacklist.CheckBlacklistEntry(blacklistName, entryID)
	local blacklist = ml_blacklist.blacklist[blacklistName]
	if blacklist[entryID] then
		return true
	end
    
    return false
end

function ml_blacklist.GetEntryTime(blacklistName, entryID)
    local blacklist = ml_blacklist.blacklist[blacklistName]
    if blacklist and blacklist[entryID] then
        if (blacklist[entryID].time == true) then
            return true
        else
            return blacklist[entryID].time - ml_global_information.Now
        end
	else
        return nil
    end
end

-- adds a new entry to the named blacklist for the given time duration
-- if time == true then the entry is permanent for the duration of the session
function ml_blacklist.AddBlacklistEntry(blacklistName, entryID, entryName, entryTime)
	local blacklist = ml_blacklist.blacklist[blacklistName]
    if (blacklist) then
        if (not blacklist[entryID]) then
            blacklist[entryID] = { time = entryTime, name = entryName } 
            ml_blacklist_mgr.WriteBlacklistFile(ml_blacklist_mgr.path)
        end
        return true
    end
    
    return false
end

function ml_blacklist.BlacklistExists(blacklistName)
    return ml_blacklist.blacklist[blacklistName] ~= nil
end

function ml_blacklist.GetExcludeString(blacklistName)
    local excludeString = ""
	local blacklist = ml_blacklist.blacklist[blacklistName]
    for id, entry in pairs(blacklist) do
        excludeString = excludeString .. id .. ";"
    end
    
    if (excludeString ~= "") then
        -- strip off trailing comma
        return excludeString:sub(1,excludeString:len() - 1) 
    else
        return nil
    end
end

function ml_blacklist.GetEntryID(blacklistName, entryName)
    local blacklist = ml_blacklist.blacklist[blacklistName]
    if (blacklist) then
        for id, entry in pairs(blacklist) do
            if entry.name == entryName then
                return id
            end
        end
    end
    
    return nil
end

function ml_blacklist.DeleteEntry(blacklistName, entryID)
    local blacklist = ml_blacklist.blacklist[blacklistName]
	if blacklist[entryID] then
		blacklist[entryID] = nil
        ml_blacklist_mgr.WriteBlacklistFile(ml_blacklist_mgr.path)
        return true
	end
    
    return false
end
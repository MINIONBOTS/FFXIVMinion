--ml_blacklist is a general framework for creating and using blacklists 
blacklist = {}

-- checks for temporarily blacklisted entries and removed them if time is up
function ClearBlacklists()

end

-- creates a new blacklist and assigns clearThrottle as the timer to check 
-- for temp entries to remove
function CreateBlacklist(blacklistName, clearThrottle)
    blacklist[black
end

-- checks ALL blacklists to see if entryName exists
-- use this ONLY if you're sure your blacklists have unique types
function IsBlacklisted(entryName)

end

-- checks only the named blacklist to see if entryName exists
function CheckBlacklistEntry(blacklistName, entryName)

end

-- adds a new entry to the named blacklist for the given time duration
-- if time == -1 then the entry is permanent for the duration of the session
function AddBlacklistEntry(blacklistName, entryName, time)

end
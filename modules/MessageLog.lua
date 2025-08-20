-- MessageLog.lua - Guild message logging for GuildItemScanner
local addonName, addon = ...
addon.MessageLog = addon.MessageLog or {}
local MessageLog = addon.MessageLog

-- Module references - use addon namespace to avoid loading order issues

-- Message History tracking
local MAX_MESSAGE_LOG = 200
local messageLog = {}

-- Log a guild message with processing details
function MessageLog.LogMessage(sender, message, itemCount, wasWTB, wasFiltered, alertType)
    local entry = {
        timestamp = time(),
        date = date("%Y-%m-%d"),
        time = date("%H:%M:%S"),
        sender = sender or "Unknown",
        message = message or "",
        itemCount = itemCount or 0,
        wasWTB = wasWTB or false,
        wasFiltered = wasFiltered or false,
        alertType = alertType -- "recipe"/"material"/"bag"/"potion"/"equipment"/nil
    }
    
    table.insert(messageLog, 1, entry)
    
    -- Maintain max log size with automatic rotation
    while #messageLog > MAX_MESSAGE_LOG do
        table.remove(messageLog)
    end
    
    -- Save to persistent storage after each message
    MessageLog.SaveMessageLog()
    
    if addon.Config and addon.Config.Get("debugMode") then
        local alertText = alertType and (" | Alert: " .. alertType) or ""
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Message logged: %s | Items: %d | WTB: %s | Filtered: %s%s", 
            sender, itemCount, tostring(wasWTB), tostring(wasFiltered), alertText))
    end
end

-- Get message log
function MessageLog.GetMessageLog()
    return messageLog
end

-- Display message log
function MessageLog.ShowMessageLog(count)
    if #messageLog == 0 then
        print("|cff00ff00[GuildItemScanner]|r No guild messages logged yet")
        return
    end
    
    -- Default to 30 messages, allow override up to maximum stored
    local displayCount = count or 30
    displayCount = math.min(displayCount, #messageLog) -- Don't exceed available messages
    displayCount = math.max(displayCount, 1) -- At least 1 message
    
    print(string.format("|cff00ff00[GuildItemScanner]|r Guild Message Log (%d entries):", #messageLog))
    print(string.format("|cffFFD700Last %d messages:|r", displayCount))
    
    for i, entry in ipairs(messageLog) do
        if i <= displayCount then
            local sender = entry.sender and string.sub(entry.sender, 1, 12) or "Unknown"
            local rawMessage = entry.message or ""
            
            -- Convert item links to readable names
            local displayMessage = rawMessage
            displayMessage = string.gsub(displayMessage, "|H([^|]*)|h%[([^%]]*)%]|h", "[%2]")
            displayMessage = string.gsub(displayMessage, "|c[a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]", "")
            displayMessage = string.gsub(displayMessage, "|r", "")
            
            -- Truncate message with ellipsis if needed
            local message = displayMessage
            if string.len(displayMessage) > 150 then
                message = string.sub(displayMessage, 1, 150) .. "..."
            end
            
            -- Format status information
            local statusParts = {}
            if entry.itemCount > 0 then
                table.insert(statusParts, "Items: " .. entry.itemCount)
            end
            if entry.wasWTB then
                table.insert(statusParts, "WTB: Yes")
            end
            if entry.wasFiltered then
                table.insert(statusParts, "Filtered")
            end
            if entry.alertType then
                table.insert(statusParts, "Alert: " .. entry.alertType)
            end
            
            local statusText = ""
            if #statusParts > 0 then
                statusText = " |cff808080→ " .. table.concat(statusParts, " | ") .. "|r"
            end
            
            print(string.format("|cff888888[%s]|r |cffFFFFFF%s:|r %s%s", 
                entry.time, sender, message, statusText))
        end
    end
    
    if #messageLog > 30 then
        print(string.format("|cff808080... and %d more entries (total: %d messages tracked)|r", 
            (#messageLog - 30), #messageLog))
    end
    
    print("|cff808080Messages are automatically logged and persist across sessions|r")
end

-- Save message log to persistent storage
function MessageLog.SaveMessageLog()
    if GuildItemScannerDB then
        GuildItemScannerDB.messageLog = messageLog
    end
end

-- Load message log from persistent storage
function MessageLog.LoadMessageLog()
    if GuildItemScannerDB and GuildItemScannerDB.messageLog then
        messageLog = GuildItemScannerDB.messageLog
        
        -- Ensure log doesn't exceed current limit (in case limit was changed)
        while #messageLog > MAX_MESSAGE_LOG do
            table.remove(messageLog)
        end
    end
end

-- Initialize MessageLog module
function MessageLog.Initialize()
    MessageLog.LoadMessageLog()
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r MessageLog module initialized")
        print("  Message history loaded: " .. #messageLog .. " entries")
    end
end

-- Get MessageLog stats (for status display)
function MessageLog.GetStats()
    local oldestEntry = messageLog[#messageLog]
    local newestEntry = messageLog[1]
    
    return {
        totalEntries = #messageLog,
        maxEntries = MAX_MESSAGE_LOG,
        oldestEntry = oldestEntry and oldestEntry.time or "None",
        newestEntry = newestEntry and newestEntry.time or "None"
    }
end
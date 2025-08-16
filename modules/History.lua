-- History.lua - History tracking and management for GuildItemScanner
local addonName, addon = ...
addon.History = addon.History or {}
local History = addon.History

local Config = addon.Config

-- Constants
local MAX_HISTORY = 50
local MAX_UNCACHED_HISTORY = 20
local alertHistory = {}
local uncachedHistory = {}

-- Add entry to history
function History.AddEntry(itemLink, playerName, itemType)
    local entry = {
        time = date("%H:%M:%S"),
        date = date("%Y-%m-%d"),
        player = playerName,
        item = itemLink,
        type = itemType or "Equipment",
        timestamp = time()
    }
    
    table.insert(alertHistory, 1, entry)
    
    -- Maintain max history size
    while #alertHistory > MAX_HISTORY do
        table.remove(alertHistory)
    end
    
    -- Save to persistent storage
    History.Save()
end

-- Add uncached item to history
function History.AddUncached(itemLink, playerName, message)
    local entry = {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        message = message and message:sub(1, 50) or "Uncached item"
    }
    
    table.insert(uncachedHistory, 1, entry)
    
    -- Maintain max uncached history size
    while #uncachedHistory > MAX_UNCACHED_HISTORY do
        table.remove(uncachedHistory)
    end
    
    -- Save to persistent storage
    History.Save()
end

-- Save history to SavedVariables
function History.Save()
    if GuildItemScannerDB then
        GuildItemScannerDB.alertHistory = alertHistory
        GuildItemScannerDB.uncachedHistory = uncachedHistory
    end
end

-- Load history from SavedVariables
function History.Load()
    if GuildItemScannerDB then
        if GuildItemScannerDB.alertHistory then
            alertHistory = GuildItemScannerDB.alertHistory
            
            -- Ensure we don't exceed max history
            while #alertHistory > MAX_HISTORY do
                table.remove(alertHistory)
            end
        end
        
        if GuildItemScannerDB.uncachedHistory then
            uncachedHistory = GuildItemScannerDB.uncachedHistory
            
            -- Ensure we don't exceed max uncached history
            while #uncachedHistory > MAX_UNCACHED_HISTORY do
                table.remove(uncachedHistory)
            end
        end
    end
end

-- Clear all history
function History.ClearHistory()
    alertHistory = {}
    uncachedHistory = {}
    History.Save()
end

-- Get uncached history
function History.GetUncachedHistory()
    return uncachedHistory
end

-- Show history with optional filtering
function History.ShowHistory(filter)
    if #alertHistory == 0 then
        print("|cff00ff00[GuildItemScanner]|r No alert history found.")
        return
    end
    
    filter = filter and filter:lower() or nil
    local displayed = 0
    local maxDisplay = 20
    
    print("|cff00ff00[GuildItemScanner]|r Alert History" .. (filter and " (filtered by: " .. filter .. ")" or "") .. ":")
    
    for i, entry in ipairs(alertHistory) do
        if displayed >= maxDisplay then
            print("  ... (showing first " .. maxDisplay .. " entries, " .. (#alertHistory - maxDisplay) .. " more available)")
            break
        end
        
        local shouldShow = true
        
        if filter then
            local itemName = string.match(entry.item, "|h%[(.-)%]|h") or ""
            local playerName = entry.player or ""
            local itemType = entry.type or ""
            
            shouldShow = string.find(itemName:lower(), filter) or 
                        string.find(playerName:lower(), filter) or 
                        string.find(itemType:lower(), filter)
        end
        
        if shouldShow then
            local typeColors = {
                Equipment = "|cff00ff00",
                Recipe = "|cffffcc00", 
                Material = "|cffffff00",
                Bag = "|cffff69b4",
                Potion = "|cffcc99ff"
            }
            local typeColor = typeColors[entry.type] or "|cffffffff"
            
            print(string.format("  %s[%s]%s %s%s|r from %s (%s)", 
                typeColor, entry.type, "|r", typeColor, entry.item, entry.player, entry.time))
            displayed = displayed + 1
        end
    end
    
    if displayed == 0 and filter then
        print("  No entries found matching filter: " .. filter)
    end
end

-- Get history statistics
function History.GetStats()
    local stats = {
        total = #alertHistory,
        byType = {},
        byPlayer = {},
        recentCount = 0
    }
    
    local recentThreshold = time() - (24 * 60 * 60) -- Last 24 hours
    
    for _, entry in ipairs(alertHistory) do
        -- Count by type
        stats.byType[entry.type] = (stats.byType[entry.type] or 0) + 1
        
        -- Count by player
        stats.byPlayer[entry.player] = (stats.byPlayer[entry.player] or 0) + 1
        
        -- Count recent entries
        if entry.timestamp and entry.timestamp > recentThreshold then
            stats.recentCount = stats.recentCount + 1
        end
    end
    
    return stats
end

-- Show detailed statistics
function History.ShowStats()
    local stats = History.GetStats()
    
    print("|cff00ff00[GuildItemScanner]|r History Statistics:")
    print("  Total alerts: " .. stats.total)
    print("  Last 24 hours: " .. stats.recentCount)
    
    if stats.total > 0 then
        print(" |cffFFD700By Type:|r")
        local sortedTypes = {}
        for type, count in pairs(stats.byType) do
            table.insert(sortedTypes, {type = type, count = count})
        end
        table.sort(sortedTypes, function(a, b) return a.count > b.count end)
        
        for _, data in ipairs(sortedTypes) do
            print(string.format("  %s: %d", data.type, data.count))
        end
        
        print(" |cffFFD700Top Players:|r")
        local sortedPlayers = {}
        for player, count in pairs(stats.byPlayer) do
            table.insert(sortedPlayers, {player = player, count = count})
        end
        table.sort(sortedPlayers, function(a, b) return a.count > b.count end)
        
        local maxPlayers = math.min(5, #sortedPlayers)
        for i = 1, maxPlayers do
            local data = sortedPlayers[i]
            print(string.format("  %s: %d alerts", data.player, data.count))
        end
    end
end

-- Export history to a readable format
function History.ExportHistory()
    if #alertHistory == 0 then
        print("|cff00ff00[GuildItemScanner]|r No history to export.")
        return
    end
    
    print("|cff00ff00[GuildItemScanner]|r Exporting history (" .. #alertHistory .. " entries):")
    print("Date,Time,Player,Type,Item")
    
    for _, entry in ipairs(alertHistory) do
        local itemName = string.match(entry.item, "|h%[(.-)%]|h") or "Unknown Item"
        print(string.format("%s,%s,%s,%s,%s", 
            entry.date or "Unknown", 
            entry.time, 
            entry.player, 
            entry.type, 
            itemName))
    end
end

-- Get recent entries by type
function History.GetRecentByType(itemType, hours)
    hours = hours or 24
    local threshold = time() - (hours * 60 * 60)
    local recent = {}
    
    for _, entry in ipairs(alertHistory) do
        if entry.type == itemType and entry.timestamp and entry.timestamp > threshold then
            table.insert(recent, entry)
        end
    end
    
    return recent
end

-- Get history for a specific player
function History.GetPlayerHistory(playerName)
    local playerHistory = {}
    
    for _, entry in ipairs(alertHistory) do
        if entry.player and string.lower(entry.player) == string.lower(playerName) then
            table.insert(playerHistory, entry)
        end
    end
    
    return playerHistory
end

-- Search history by item name
function History.SearchByItem(itemName)
    local results = {}
    itemName = itemName:lower()
    
    for _, entry in ipairs(alertHistory) do
        local entryItemName = string.match(entry.item, "|h%[(.-)%]|h")
        if entryItemName and string.find(entryItemName:lower(), itemName) then
            table.insert(results, entry)
        end
    end
    
    return results
end
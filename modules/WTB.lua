-- WTB.lua - Want To Buy request tracking for GuildItemScanner
local addonName, addon = ...
addon.WTB = addon.WTB or {}
local WTB = addon.WTB

-- Module references - use addon namespace to avoid loading order issues

-- WTB History tracking
local MAX_WTB_HISTORY = 20
local wtbHistory = {}

-- Parse quantity from message
local function parseQuantity(message, itemName)
    -- Remove the item link to avoid false matches
    local msgWithoutLink = string.gsub(message, "%[" .. itemName .. "%]", "")
    
    -- Patterns for quantity (in order of specificity)
    local patterns = {
        "(%d+)x",           -- "20x"
        "x(%d+)",           -- "x20"  
        "(%d+) x",          -- "20 x"
        "x (%d+)",          -- "x 20"
        "(%d+) stacks?",    -- "20 stack" or "20 stacks"
        "(%d+) of",         -- "20 of [item]"
        "need (%d+)",       -- "need 20"
        "want (%d+)",       -- "want 20"
        "buying (%d+)",     -- "buying 20"
        "(%d+)$",           -- Number at end of message
        "^(%d+)",           -- Number at start of message
        " (%d+) "           -- Number surrounded by spaces
    }
    
    for _, pattern in ipairs(patterns) do
        local quantity = string.match(msgWithoutLink, pattern)
        if quantity then
            local num = tonumber(quantity)
            -- Reasonable quantity range (1-10000)
            if num and num >= 1 and num <= 10000 then
                return num
            end
        end
    end
    
    return nil
end

-- Parse price from message
local function parsePrice(message)
    -- Convert to lowercase for easier matching
    local lowerMsg = string.lower(message)
    
    -- Price patterns (in order of specificity)
    local patterns = {
        -- Gold and silver combinations
        "(%d+)g(%d+)s",                    -- "100g50s"
        "(%d+)g (%d+)s",                   -- "100g 50s"  
        "(%d+) gold (%d+) silver",        -- "100 gold 50 silver"
        "(%d+) gold (%d+) sil",           -- "100 gold 50 sil"
        
        -- Gold only
        "(%d+)g",                          -- "100g"
        "(%d+) gold",                      -- "100 gold"
        "(%d+) g ",                        -- "100 g "
        
        -- Silver only
        "(%d+)s",                          -- "50s"
        "(%d+) silver",                    -- "50 silver"
        "(%d+) sil",                       -- "50 sil"
        "(%d+) s ",                        -- "50 s "
        
        -- Copper only
        "(%d+)c",                          -- "50c"
        "(%d+) copper",                    -- "50 copper"
        "(%d+) cop",                       -- "50 cop"
    }
    
    -- Try gold+silver patterns first
    for i = 1, 4 do
        local gold, silver = string.match(lowerMsg, patterns[i])
        if gold and silver then
            return gold .. "g" .. silver .. "s"
        end
    end
    
    -- Try single currency patterns
    for i = 5, #patterns do
        local amount = string.match(lowerMsg, patterns[i])
        if amount then
            local num = tonumber(amount)
            if num and num >= 1 and num <= 999999 then -- Reasonable price range
                if i <= 7 then
                    return amount .. "g"  -- Gold patterns
                elseif i <= 11 then
                    return amount .. "s"  -- Silver patterns
                else
                    return amount .. "c"  -- Copper patterns
                end
            end
        end
    end
    
    return nil
end

-- Parse WTB message for item, quantity, and price
function WTB.ParseWTBMessage(message, playerName)
    if not message or not playerName then return end
    
    -- Extract item links from message
    local itemLinks = {}
    for itemLink in string.gmatch(message, "|c%x+|H.-|h%[.-%]|h|r") do
        table.insert(itemLinks, itemLink)
    end
    
    -- If no item links found, try to extract item names in brackets
    if #itemLinks == 0 then
        for itemName in string.gmatch(message, "%[(.-)%]") do
            -- Create a simple item link format for display
            table.insert(itemLinks, "[" .. itemName .. "]")
        end
    end
    
    -- Process each item found
    for _, itemLink in ipairs(itemLinks) do
        local itemName = string.match(itemLink, "%[(.-)%]")
        if itemName then
            local quantity = parseQuantity(message, itemName)
            local price = parsePrice(message)
            
            WTB.AddWTBEntry(playerName, itemLink, quantity, price, message)
        end
    end
end

-- Add WTB entry to history
function WTB.AddWTBEntry(playerName, itemLink, quantity, price, rawMessage)
    local entry = {
        time = date("%H:%M:%S"),
        date = date("%Y-%m-%d"),
        player = playerName,
        itemLink = itemLink,
        itemName = string.match(itemLink, "%[(.-)%]") or itemLink,
        quantity = quantity,
        price = price,
        rawMessage = rawMessage or "",
        timestamp = time()
    }
    
    table.insert(wtbHistory, 1, entry)
    
    -- Maintain max history size
    while #wtbHistory > MAX_WTB_HISTORY do
        table.remove(wtbHistory)
    end
    
    -- Save to persistent storage
    WTB.SaveWTBHistory()
    
    if addon.Config and addon.Config.Get("debugMode") then
        local qtyText = quantity and tostring(quantity) or "?"
        local priceText = price or "?"
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r WTB logged: %s wants %s %s for %s", 
            playerName, qtyText, entry.itemName, priceText))
    end
end

-- Get WTB history
function WTB.GetWTBHistory()
    return wtbHistory
end

-- Display WTB history
function WTB.ShowWTBHistory()
    if #wtbHistory == 0 then
        print("|cff00ff00[GuildItemScanner]|r No WTB history found")
        return
    end
    
    print("|cff00ff00[GuildItemScanner]|r WTB History (" .. #wtbHistory .. " entries):")
    print("|cffFFD700Time     | Player      | Item                    | Qty  | Price | Message|r")
    
    for i, entry in ipairs(wtbHistory) do
        if i <= 15 then -- Limit display to avoid spam
            local playerName = entry.player and string.sub(entry.player, 1, 11) or "Unknown"
            local itemDisplay = entry.itemName and string.sub(entry.itemName, 1, 22) or "Unknown"
            local qtyDisplay = entry.quantity and tostring(entry.quantity) or "-"
            local priceDisplay = entry.price or "-"
            local messageDisplay = entry.rawMessage and string.sub(entry.rawMessage, 1, 30) or ""
            
            -- Pad fields for alignment
            playerName = string.format("%-11s", playerName)
            itemDisplay = string.format("%-22s", itemDisplay)
            qtyDisplay = string.format("%-4s", qtyDisplay)
            priceDisplay = string.format("%-5s", priceDisplay)
            
            print(string.format("%s | %s | %s | %s | %s | %s", 
                entry.time, playerName, itemDisplay, qtyDisplay, priceDisplay, messageDisplay))
        end
    end
    
    if #wtbHistory > 15 then
        print("|cff808080... and " .. (#wtbHistory - 15) .. " more entries (use /gis wtbclear to clear)|r")
    end
end

-- Clear WTB history
function WTB.ClearWTBHistory()
    wtbHistory = {}
    WTB.SaveWTBHistory()
    print("|cff00ff00[GuildItemScanner]|r WTB history cleared")
end

-- Save WTB history to persistent storage
function WTB.SaveWTBHistory()
    if GuildItemScannerDB then
        GuildItemScannerDB.wtbHistory = wtbHistory
    end
end

-- Load WTB history from persistent storage
function WTB.LoadWTBHistory()
    if GuildItemScannerDB and GuildItemScannerDB.wtbHistory then
        wtbHistory = GuildItemScannerDB.wtbHistory
    end
end

-- Initialize WTB module
function WTB.Initialize()
    WTB.LoadWTBHistory()
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r WTB module initialized")
        print("  WTB history loaded: " .. #wtbHistory .. " entries")
    end
end

-- Get WTB stats (for future use)
function WTB.GetStats()
    return {
        totalEntries = #wtbHistory,
        oldestEntry = wtbHistory[#wtbHistory] and wtbHistory[#wtbHistory].time or "None",
        newestEntry = wtbHistory[1] and wtbHistory[1].time or "None"
    }
end
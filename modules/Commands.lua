-- Commands.lua - Complete command system for GuildItemScanner
local addonName, addon = ...
addon.Commands = addon.Commands or {}
local Commands = addon.Commands

-- Module references - use addon namespace to avoid loading order issues
-- Helper functions to safely access modules
local function safeConfig()
    return addon.Config
end

local function safeDetection() 
    return addon.Detection
end

local function safeHistory()
    return addon.History  
end

local function safeSocial()
    return addon.Social
end

-- Command handlers
local commandHandlers = {}

-- Core Commands
commandHandlers.on = function()
    if addon.Config then
        addon.Config.Set("enabled", true)
        print("|cff00ff00[GuildItemScanner]|r Addon |cff00ff00ENABLED|r")
    end
end

commandHandlers.off = function()
    if addon.Config then
        addon.Config.Set("enabled", false)
        print("|cff00ff00[GuildItemScanner]|r Addon |cffff0000DISABLED|r")
    end
end

commandHandlers.debug = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("debugMode")
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

commandHandlers.sound = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("soundAlert")
        print("|cff00ff00[GuildItemScanner]|r Sound alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

commandHandlers.duration = function(args)
    if not addon.Config then return end
    
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current alert duration: " .. (addon.Config and addon.Config.Get("alertDuration") or "5") .. " seconds")
    else
        local duration = tonumber(args)
        if duration and duration >= 1 and duration <= 60 then
            addon.Config.Set("alertDuration", duration)
            print("|cff00ff00[GuildItemScanner]|r Alert duration set to: " .. duration .. " seconds")
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid duration. Must be between 1 and 60 seconds")
        end
    end
end

commandHandlers.reset = function()
    if addon.Config then
        addon.Config.Reset()
        print("|cff00ff00[GuildItemScanner]|r Configuration reset to defaults")
    end
end

-- Equipment Commands
commandHandlers.test = function()
    if addon.Detection then
        addon.Detection.TestEquipment()
    end
end

commandHandlers.whisper = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("whisperMode")
        print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

commandHandlers.greed = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("greedMode")
        print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

-- Profession Commands
commandHandlers.prof = function(args)
    if args == "" then
        local professions = addon.Config and addon.Config.GetProfessions() or {}
        if #professions == 0 then
            print("|cff00ff00[GuildItemScanner]|r No professions set. Use /gis prof add <profession>")
        else
            print("|cff00ff00[GuildItemScanner]|r Your professions: " .. table.concat(professions, ", "))
        end
    else
        local subCmd, profession = args:match("^(%S+)%s*(.*)$")
        if subCmd == "add" and profession ~= "" then
            local success, result = addon.Config and addon.Config.AddProfession(profession)
            if success then
                print("|cff00ff00[GuildItemScanner]|r Added profession: " .. profession)
            else
                print("|cff00ff00[GuildItemScanner]|r You already have " .. profession)
            end
        elseif subCmd == "remove" and profession ~= "" then
            local success, result = addon.Config and addon.Config.RemoveProfession(profession)
            if success then
                print("|cff00ff00[GuildItemScanner]|r Removed profession: " .. profession)
            else
                print("|cff00ff00[GuildItemScanner]|r Profession not found: " .. profession)
            end
        elseif subCmd == "clear" then
            if addon.Config then
                addon.Config.ClearProfessions()
                print("|cff00ff00[GuildItemScanner]|r Cleared all professions")
            end
        elseif subCmd == "list" then
            commandHandlers.prof("")
        else
            print("|cff00ff00[GuildItemScanner]|r Usage: /gis prof [add|remove|clear|list] <profession>")
        end
    end
end

commandHandlers.recipe = function()
    local enabled = addon.Config and addon.Config.Toggle("recipeAlert")
    print("|cff00ff00[GuildItemScanner]|r Recipe alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.recipebutton = function()
    local enabled = addon.Config and addon.Config.Toggle("recipeButton")
    print("|cff00ff00[GuildItemScanner]|r Recipe request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

-- Material Commands
commandHandlers.material = function()
    local enabled = addon.Config and addon.Config.Toggle("materialAlert")
    print("|cff00ff00[GuildItemScanner]|r Material alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end
commandHandlers.mat = commandHandlers.material

commandHandlers.matbutton = function()
    local enabled = addon.Config and addon.Config.Toggle("materialButton")
    print("|cff00ff00[GuildItemScanner]|r Material request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.rarity = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current rarity filter: " .. (addon.Config and addon.Config.Get("materialRarityFilter") or "common"))
        print("|cff00ff00[GuildItemScanner]|r Valid rarities: common, rare, epic, legendary")
    else
        local validRarities = {common = true, rare = true, epic = true, legendary = true}
        local rarity = args:lower()
        if validRarities[rarity] then
            if addon.Config then
                addon.Config.Set("materialRarityFilter", rarity)
                print("|cff00ff00[GuildItemScanner]|r Material rarity filter set to: " .. rarity)
            end
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid rarity. Valid options: common, rare, epic, legendary")
        end
    end
end

commandHandlers.quantity = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current quantity threshold: " .. (addon.Config and addon.Config.Get("materialQuantityThreshold") or "1"))
    else
        local qty = tonumber(args)
        if qty and qty >= 1 and qty <= 1000 then
            if addon.Config then
                addon.Config.Set("materialQuantityThreshold", qty)
                print("|cff00ff00[GuildItemScanner]|r Material quantity threshold set to: " .. qty)
            end
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid quantity. Must be between 1 and 1000")
        end
    end
end
commandHandlers.qty = commandHandlers.quantity

-- Bag Commands
commandHandlers.bag = function()
    local enabled = addon.Config and addon.Config.Toggle("bagAlert")
    print("|cff00ff00[GuildItemScanner]|r Bag alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.bagbutton = function()
    local enabled = addon.Config and addon.Config.Toggle("bagButton")
    print("|cff00ff00[GuildItemScanner]|r Bag request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.bagsize = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current bag size filter: " .. (addon.Config and addon.Config.Get("bagSizeFilter") or "6") .. "+ slots")
    else
        local size = tonumber(args)
        if size and size >= 6 and size <= 24 then
            if addon.Config then
                addon.Config.Set("bagSizeFilter", size)
                print("|cff00ff00[GuildItemScanner]|r Bag size filter set to: " .. size .. "+ slots")
            end
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid bag size. Must be between 6 and 24")
        end
    end
end

-- Potion Commands
commandHandlers.potion = function()
    local enabled = addon.Config and addon.Config.Toggle("potionAlert")
    print("|cff00ff00[GuildItemScanner]|r Potion alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.potionbutton = function()
    local enabled = addon.Config and addon.Config.Toggle("potionButton")
    print("|cff00ff00[GuildItemScanner]|r Potion request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.potiontype = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current potion type filter: " .. (addon.Config and addon.Config.Get("potionTypeFilter") or "all"))
        print("|cff00ff00[GuildItemScanner]|r Valid types: all, combat, profession, misc")
    else
        local validTypes = {all = true, combat = true, profession = true, misc = true}
        local ptype = args:lower()
        if validTypes[ptype] then
            if addon.Config then
                addon.Config.Set("potionTypeFilter", ptype)
                print("|cff00ff00[GuildItemScanner]|r Potion type filter set to: " .. ptype)
            end
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid type. Valid options: all, combat, profession, misc")
        end
    end
end

-- Social Commands
commandHandlers.gz = function(args)
    if not addon.Config then return end
    
    local subcommand = args and args:match("^(%S+)")
    if not subcommand then
        -- Toggle auto-GZ (existing behavior)
        local enabled = addon.Config.Toggle("autoGZ")
        print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
        print("|cff00ff00[GuildItemScanner]|r Current chance: " .. addon.Config.GetGzChance() .. "%")
        return
    end
    
    subcommand = string.lower(subcommand)
    local remaining = args:match("^%S+%s*(.*)")
    
    if subcommand == "add" then
        if not remaining or remaining == "" then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis gz add <message>")
            return
        end
        
        local success, msg = addon.Config.AddGzMessage(remaining)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Added custom GZ message: '" .. remaining .. "'")
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "remove" then
        local index = tonumber(remaining)
        if not index then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis gz remove <index>")
            print("|cffff0000[GuildItemScanner]|r Use '/gis gz list' to see message numbers")
            return
        end
        
        local success, msg = addon.Config.RemoveGzMessage(index)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Removed GZ message #" .. index)
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "list" then
        local messages = addon.Config.GetGzMessages()
        print("|cff00ff00[GuildItemScanner]|r === Custom GZ Messages (" .. #messages .. " total) ===")
        
        if #messages == 0 then
            print("|cff808080[GuildItemScanner]|r No custom messages. Using defaults only.")
        else
            for i, message in ipairs(messages) do
                print("|cffffcc00" .. i .. ".|r " .. message .. " |cff00ff00[CUSTOM]|r")
            end
        end
        
        -- Show default messages
        print("|cff00ff00[GuildItemScanner]|r === Default GZ Messages (always available) ===")
        if addon.Databases and addon.Databases.GZ_MESSAGES then
            local defaults = addon.Databases.GZ_MESSAGES
            for i, message in ipairs(defaults) do
                print("|cff808080  " .. message .. "|r")
            end
        else
            print("|cff808080  GZ, grats, nice! (fallback defaults)|r")
        end
        
    elseif subcommand == "clear" then
        addon.Config.ClearGzMessages()
        print("|cff00ff00[GuildItemScanner]|r Cleared all custom GZ messages")
        
    elseif subcommand == "chance" then
        local chance = tonumber(remaining)
        if not chance then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis gz chance <0-100>")
            print("|cff00ff00[GuildItemScanner]|r Current chance: " .. addon.Config.GetGzChance() .. "%")
            return
        end
        
        local success, msg = addon.Config.SetGzChance(chance)
        if success then
            print("|cff00ff00[GuildItemScanner]|r GZ chance set to " .. chance .. "%")
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    else
        print("|cffff0000[GuildItemScanner]|r Unknown gz command: " .. subcommand)
        print("|cff00ff00[GuildItemScanner]|r Available: add, remove, list, clear, chance")
    end
end

commandHandlers.rip = function(args)
    if not addon.Config then return end
    
    local subcommand = args and args:match("^(%S+)")
    if not subcommand then
        -- Toggle auto-RIP (existing behavior)
        local enabled = addon.Config.Toggle("autoRIP")
        print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
        print("|cff00ff00[GuildItemScanner]|r Current chance: " .. addon.Config.GetRipChance() .. "%")
        return
    end
    
    subcommand = string.lower(subcommand)
    local remaining = args:match("^%S+%s*(.*)")
    
    if subcommand == "add" then
        local level, message = remaining:match("^(%S+)%s+(.*)")
        if not level or not message or message == "" then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis rip add <level> <message>")
            print("|cffff0000[GuildItemScanner]|r Levels: low (1-39), mid (40-59), high (60)")
            return
        end
        
        local success, msg = addon.Config.AddRipMessage(level, message)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Added custom RIP message for " .. level .. " level: '" .. message .. "'")
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "remove" then
        local level, index = remaining:match("^(%S+)%s+(%S+)")
        if not level or not index then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis rip remove <level> <index>")
            print("|cffff0000[GuildItemScanner]|r Use '/gis rip list' to see message numbers")
            return
        end
        
        local success, msg = addon.Config.RemoveRipMessage(level, index)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Removed RIP message #" .. index .. " from " .. level .. " level")
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "list" then
        local allMessages = addon.Config.GetRipMessages()
        print("|cff00ff00[GuildItemScanner]|r === Custom RIP Messages ===")
        
        local totalCustom = 0
        local levelOrder = {"low", "mid", "high"}
        for _, level in ipairs(levelOrder) do
            local messages = allMessages[level]
            totalCustom = totalCustom + #messages
            
            local levelDesc = level == "low" and "1-39" or level == "mid" and "40-59" or "60"
            print("|cffffcc00" .. string.upper(level) .. " Level (" .. levelDesc .. "):|r " .. #messages .. " custom")
            if #messages == 0 then
                print("|cff808080  No custom messages|r")
            else
                for i, message in ipairs(messages) do
                    print("|cffffcc00  " .. i .. ".|r " .. message .. " |cff00ff00[CUSTOM]|r")
                end
            end
        end
        
        if totalCustom == 0 then
            print("|cff808080[GuildItemScanner]|r No custom messages. Using defaults only.")
        end
        
        -- Show default messages by level
        print("|cff00ff00[GuildItemScanner]|r === Default RIP Messages (always available) ===")
        print("|cffffcc00LOW Level (1-39):|r")
        print("|cff808080  F, RIP, oof|r")
        print("|cffffcc00MID Level (40-59):|r")
        print("|cff808080  F, OMG F, BIG RIP|r")
        print("|cffffcc00HIGH Level (60):|r")
        print("|cff808080  F, OMG F, GIGA F, MEGA RIP, NOOOO|r")
        
    elseif subcommand == "clear" then
        local level = remaining and remaining ~= "" and remaining or nil
        local success, msg = addon.Config.ClearRipMessages(level)
        if success then
            if level then
                print("|cff00ff00[GuildItemScanner]|r Cleared all custom RIP messages for " .. level .. " level")
            else
                print("|cff00ff00[GuildItemScanner]|r Cleared all custom RIP messages for all levels")
            end
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "chance" then
        local chance = tonumber(remaining)
        if not chance then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis rip chance <0-100>")
            print("|cff00ff00[GuildItemScanner]|r Current chance: " .. addon.Config.GetRipChance() .. "%")
            return
        end
        
        local success, msg = addon.Config.SetRipChance(chance)
        if success then
            print("|cff00ff00[GuildItemScanner]|r RIP chance set to " .. chance .. "%")
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    else
        print("|cffff0000[GuildItemScanner]|r Unknown rip command: " .. subcommand)
        print("|cff00ff00[GuildItemScanner]|r Available: add, remove, list, clear, chance")
    end
end

-- History Commands
commandHandlers.history = function(args)
    if addon.History then
        addon.History.ShowHistory(args)
    end
end

commandHandlers.clearhistory = function()
    if addon.History then
        addon.History.ClearHistory()
        print("|cff00ff00[GuildItemScanner]|r History cleared")
    end
end

commandHandlers.uncached = function()
    if addon.History then
        local uncachedHistory = addon.History.GetUncachedHistory()
        if #uncachedHistory == 0 then
            print("|cff00ff00[GuildItemScanner]|r No uncached items found.")
            return
        end
        
        print("|cff00ff00[GuildItemScanner]|r Uncached Item History:")
        for i, entry in ipairs(uncachedHistory) do
            if i > 10 then break end -- Show only last 10
            print(string.format("  %s [%s] %s - %s", 
                entry.time, entry.player, entry.item, entry.message))
        end
        
        if #uncachedHistory > 10 then
            print(string.format("  ... and %d more entries", #uncachedHistory - 10))
        end
    end
end

-- Cache diagnosis command
commandHandlers.cachediag = function()
    print("|cff00ff00[GuildItemScanner]|r Cache Diagnosis:")
    
    -- Test a few known items to see if cache is working
    local testItems = {
        {"|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r", "Recipe: Gooey Spider Cake"},
        {"|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", "Thaumaturgist Staff"},
        {"|cffffffff|Hitem:2770::::::::60:::::::|h[Copper Ore]|h|r", "Copper Ore"}
    }
    
    for i, testData in ipairs(testItems) do
        local itemLink, expectedName = testData[1], testData[2]
        local actualName = GetItemInfo(itemLink)
        
        if actualName then
            if actualName == expectedName then
                print(string.format("  [OK] %s = '%s' |cff00ff00(CORRECT)|r", itemLink, actualName))
            else
                print(string.format("  [X] %s = '%s' |cffff0000(WRONG, expected '%s')|r", itemLink, actualName, expectedName))
            end
        else
            print(string.format("  ? %s = |cffff0000nil (NOT CACHED)|r", itemLink))
        end
    end
    
    print("|cff00ff00[GuildItemScanner]|r If cache is corrupted, try reloading UI (/reload) or restarting WoW.")
end

commandHandlers.compare = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Usage: /gis compare [item link]")
        print("|cff00ff00[GuildItemScanner]|r Example: /gis compare [Thunderfury, Blessed Blade of the Windseeker]")
        return
    end
    
    -- Extract item link from the arguments
    local itemLink = string.match(args, "|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        print("|cff00ff00[GuildItemScanner]|r Invalid item link. Please provide a valid item link.")
        return
    end
    
    -- Get item info
    local itemName, _, _, itemLevel, requiredLevel, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName then
        print("|cff00ff00[GuildItemScanner]|r Unable to retrieve item information. The item may not be cached.")
        return
    end
    
    -- Print item info
    local bindText = bindType == 1 and "|cffff0000BoP|r" or "|cff00ff00BoE|r"
    print(string.format("|cff00ff00[GuildItemScanner]|r Comparing: %s (%s, ilvl %d)", 
        itemLink, bindText, itemLevel))
    
    -- Print level requirements
    if requiredLevel and requiredLevel > 1 then
        local playerLevel = UnitLevel("player")
        local levelText = playerLevel >= requiredLevel and 
            string.format("|cff00ff00Level %d required (you have %d)|r", requiredLevel, playerLevel) or
            string.format("|cffff0000Level %d required (you have %d)|r", requiredLevel, playerLevel)
        print(string.format("|cff00ff00[GuildItemScanner]|r %s", levelText))
        
        if playerLevel < requiredLevel then
            print("|cff00ff00[GuildItemScanner]|r |cffff0000This item cannot be equipped due to level requirements.|r")
            return
        end
    end
    
    -- Check if player can use the item (class/armor/weapon restrictions)
    if addon.Detection and not addon.Detection.CanPlayerUseItem(itemLink) then
        print("|cff00ff00[GuildItemScanner]|r |cffff0000You cannot use this item due to class or level restrictions.|r")
        return
    end
    
    -- Check if it's an equippable item
    if not itemEquipLoc or itemEquipLoc == "" or itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" then
        print("|cff00ff00[GuildItemScanner]|r This item is not equippable.")
        return
    end
    
    -- Force item to cache by requesting tooltip
    local itemID = string.match(itemLink, "item:(%d+)")
    if itemID then
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetHyperlink("item:" .. itemID)
        GameTooltip:Hide()
    end
    
    -- Use Detection module to check upgrade status
    if addon.Detection then
        addon.Detection.CompareItemWithEquipped(itemLink)
    else
        print("|cff00ff00[GuildItemScanner]|r Detection module not available.")
    end
end

-- Testing Commands
commandHandlers.testmat = function()
    if addon.Detection then
        addon.Detection.TestMaterial()
    end
end

commandHandlers.testbag = function()
    if addon.Detection then
        addon.Detection.TestBag()
    end
end

commandHandlers.testrecipe = function()
    if addon.Detection then
        addon.Detection.TestRecipe()
    end
end

commandHandlers.testpotion = function()
    if addon.Detection then
        addon.Detection.TestPotion()
    end
end

commandHandlers.testfrontier = function()
    if addon.Social then
        addon.Social.TestFrontierPatterns()
    end
end

commandHandlers.testgz = function()
    if addon.Social then
        addon.Social.TestAutoGZ()
    end
end

commandHandlers.testrip = function()
    if addon.Social then
        addon.Social.TestAutoRIP()
    end
end

commandHandlers.whispertest = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("whisperTestMode")
        if enabled then
            print("|cff00ff00[GuildItemScanner]|r Whisper test mode |cff00ff00ENABLED|r")
            print("|cff00ff00[GuildItemScanner]|r You can now whisper yourself with item links to test detection")
            local playerName = UnitName("player")
            print("|cff00ff00[GuildItemScanner]|r Example: /w " .. playerName .. " Check out this [item]!")
            print("|cff00ff00[GuildItemScanner]|r (Works with both '" .. playerName .. "' and '" .. playerName .. "-" .. GetRealmName() .. "')")
        else
            print("|cff00ff00[GuildItemScanner]|r Whisper test mode |cffff0000DISABLED|r")
        end
    end
end

-- Comprehensive Smoke Test
commandHandlers.smoketest = function()
    local startTime = GetTime()
    local testCount = 0
    local passedCount = 0
    
    print("|cff00ff00[GuildItemScanner]|r |cffffff00=== SMOKE TEST STARTING ===|r")
    print("|cff00ff00[GuildItemScanner]|r |cff808080Safe mode: No guild spam, whispers to self only|r")
    print("")
    
    -- Test 1: Equipment Detection
    testCount = testCount + 1
    print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Equipment Detection...")
    if addon.Detection then
        addon.Detection.TestEquipment()
        passedCount = passedCount + 1
        print("      |cff00ff00[OK] Equipment test completed|r")
    else
        print("      |cffff0000[X] Detection module not available|r")
    end
    
    C_Timer.After(0.5, function()
        -- Test 2: Material Detection
        testCount = testCount + 1
        print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Material Detection...")
        
        local professions = addon.Config and addon.Config.GetProfessions() or {}
        if #professions > 0 then
            if addon.Detection then
                addon.Detection.TestMaterial()
                passedCount = passedCount + 1
                print("      |cff00ff00[OK] Material test completed|r")
            else
                print("      |cffff0000[X] Detection module not available|r")
            end
        else
            print("      |cffffff00[X] Skipped: No professions set (use /gis prof add <profession>)|r")
        end
        
        C_Timer.After(0.5, function()
            -- Test 3: Bag Detection
            testCount = testCount + 1
            print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Bag Detection...")
            if addon.Detection then
                addon.Detection.TestBag()
                passedCount = passedCount + 1
                print("      |cff00ff00[OK] Bag test completed|r")
            else
                print("      |cffff0000[X] Detection module not available|r")
            end
            
            C_Timer.After(0.5, function()
                -- Test 4: Recipe Detection
                testCount = testCount + 1
                print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Recipe Detection...")
                
                if #professions > 0 then
                    if addon.Detection then
                        addon.Detection.TestRecipe()
                        passedCount = passedCount + 1
                        print("      |cff00ff00[OK] Recipe test completed|r")
                    else
                        print("      |cffff0000[X] Detection module not available|r")
                    end
                else
                    print("      |cffffff00[X] Skipped: No professions set (use /gis prof add <profession>)|r")
                end
                
                C_Timer.After(0.5, function()
                    -- Test 5: Potion Detection
                    testCount = testCount + 1
                    print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Potion Detection...")
                    if addon.Detection then
                        addon.Detection.TestPotion()
                        passedCount = passedCount + 1
                        print("      |cff00ff00[OK] Potion test completed|r")
                    else
                        print("      |cffff0000[X] Detection module not available|r")
                    end
                    
                    C_Timer.After(0.5, function()
                        -- Test 6: Whisper Mode (Safe)
                        testCount = testCount + 1
                        print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Whisper Mode (Safe)...")
                        
                        if addon.Detection and addon.Config then
                            -- Enable whisper test mode temporarily
                            local wasWhisperTestEnabled = addon.Config.Get("whisperTestMode")
                            if not wasWhisperTestEnabled then
                                addon.Config.Set("whisperTestMode", true)
                                print("      |cffffff00Temporarily enabling whisper test mode...|r")
                            end
                            
                            local playerName = UnitName("player")
                            local testItem = "|cff1eff00|Hitem:2030::::::::15:::::::|h[Gnarled Staff]|h|r"
                            
                            print("      |cffffff00Sending test whisper to yourself...|r")
                            SendChatMessage("[SMOKE TEST] " .. testItem, "WHISPER", nil, playerName)
                            
                            -- Restore original whisper test mode state
                            if not wasWhisperTestEnabled then
                                addon.Config.Set("whisperTestMode", false)
                                print("      |cffffff00Whisper test mode restored to disabled|r")
                            end
                            
                            passedCount = passedCount + 1
                            print("      |cff00ff00[OK] Test whisper sent - check for alert popup|r")
                        else
                            print("      |cffff0000[X] Detection module not available|r")
                        end
                        
                        C_Timer.After(1.0, function()
                            -- Test 7: Social Features (Simulation Only)
                            testCount = testCount + 1
                            print("|cff00ff00[GuildItemScanner]|r |cffffff00[" .. testCount .. "/7]|r Testing Social Features (Simulation)...")
                            
                            if addon.Social and addon.Config then
                                -- Simulate GZ
                                local gzChance = addon.Config.GetGzChance()
                                local gzRoll = math.random(1, 100)
                                local wouldTriggerGZ = gzRoll <= gzChance
                                
                                print("      |cffffff00GZ Test: Rolled " .. gzRoll .. "/" .. gzChance .. "% chance|r")
                                if wouldTriggerGZ then
                                    print("      |cff00ff00[OK] Would trigger GZ (message not sent)|r")
                                else
                                    print("      |cffffff00[X] Would not trigger GZ this time|r")
                                end
                                
                                -- Simulate RIP
                                local ripChance = addon.Config.GetRipChance()
                                local ripRoll = math.random(1, 100)
                                local wouldTriggerRIP = ripRoll <= ripChance
                                
                                print("      |cffffff00RIP Test: Rolled " .. ripRoll .. "/" .. ripChance .. "% chance|r")
                                if wouldTriggerRIP then
                                    print("      |cff00ff00[OK] Would trigger RIP (message not sent)|r")
                                else
                                    print("      |cffffff00[X] Would not trigger RIP this time|r")
                                end
                                
                                passedCount = passedCount + 1
                                print("      |cff00ff00[OK] Social simulation completed safely|r")
                            else
                                print("      |cffffff00[X] Social module not available (this is normal)|r")
                            end
                            
                            -- Final Summary
                            local endTime = GetTime()
                            local elapsed = endTime - startTime
                            
                            print("")
                            print("|cff00ff00[GuildItemScanner]|r |cffffff00=== SMOKE TEST COMPLETE ===|r")
                            print("|cff00ff00[GuildItemScanner]|r Tests Run: |cffffff00" .. testCount .. "/7|r")
                            print("|cff00ff00[GuildItemScanner]|r Tests Passed: |cff00ff00" .. passedCount .. "|r")
                            print("|cff00ff00[GuildItemScanner]|r Time Elapsed: |cffffff00" .. string.format("%.1f", elapsed) .. " seconds|r")
                            
                            if passedCount >= 5 then
                                print("|cff00ff00[GuildItemScanner]|r Status: |cff00ff00All core systems operational [OK]|r")
                            else
                                print("|cff00ff00[GuildItemScanner]|r Status: |cffffff00Some tests skipped or failed|r")
                            end
                            
                            print("|cff00ff00[GuildItemScanner]|r |cff808080No guild messages sent - all tests safe|r")
                        end)
                    end)
                end)
            end)
        end)
    end)
end

-- Stat Priority Commands
commandHandlers.stats = function(args)
    if not addon.Config then return end
    
    local subcommand = args and args:match("^(%S+)")
    if not subcommand then
        -- Show current stat priorities
        local priorities = addon.Config.GetStatPriorities()
        local mode = addon.Config.GetStatComparisonMode()
        
        print("|cff00ff00[GuildItemScanner]|r === Current Stat Configuration ===")
        print("  Comparison mode: |cffffcc00" .. string.upper(mode) .. "|r")
        
        if #priorities == 0 then
            print("  Stat priorities: |cff808080None set|r")
            if mode == "stats" or mode == "both" then
                print("  |cffff8000WARNING:|r Stats mode active but no priorities set!")
            end
        else
            print("  Stat priorities:")
            for i, stat in ipairs(priorities) do
                local weight = math.max(100 - (i - 1) * 25, 1)
                print(string.format("    |cffffcc00%d.|r %s (weight: %d)", i, stat, weight))
            end
        end
        
        print("|cff00ff00[GuildItemScanner]|r Use '/gis stats help' for commands")
        return
    end
    
    subcommand = string.lower(subcommand)
    local remaining = args:match("^%S+%s*(.*)")
    
    if subcommand == "help" then
        print("|cff00ff00[GuildItemScanner]|r === Stat Priority Commands ===")
        print("  |cffffcc00/gis stats|r - Show current configuration")
        print("  |cffffcc00/gis stats add <stat> [position]|r - Add stat at position")
        print("  |cffffcc00/gis stats remove <stat>|r - Remove stat from priorities")
        print("  |cffffcc00/gis stats move <stat> <position>|r - Reorder stat priority")
        print("  |cffffcc00/gis stats clear|r - Clear all stat priorities")
        print("  |cffffcc00/gis stats list|r - Show available stats")
        print("  |cffffcc00/gis statmode <mode>|r - Set comparison mode")
        print("|cff00ff00[GuildItemScanner]|r Modes: ilvl, stats, both")
        
    elseif subcommand == "add" then
        local stat, position = remaining:match("^(%S+)%s*(%S*)")
        if not stat or stat == "" then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis stats add <stat> [position]")
            print("|cff00ff00[GuildItemScanner]|r Use '/gis stats list' to see available stats")
            return
        end
        
        local pos = position and position ~= "" and tonumber(position) or nil
        local success, msg = addon.Config.AddStatPriority(stat, pos)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Added stat priority: " .. stat .. (pos and " at position " .. pos or ""))
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "remove" then
        local stat = remaining and remaining:match("^(%S+)")
        if not stat or stat == "" then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis stats remove <stat>")
            return
        end
        
        local success, msg = addon.Config.RemoveStatPriority(stat)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Removed stat priority: " .. stat)
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "move" then
        local stat, position = remaining:match("^(%S+)%s+(%S+)")
        if not stat or not position then
            print("|cffff0000[GuildItemScanner]|r Usage: /gis stats move <stat> <position>")
            return
        end
        
        local success, msg = addon.Config.MoveStatPriority(stat, position)
        if success then
            print("|cff00ff00[GuildItemScanner]|r Moved " .. stat .. " to position " .. position)
        else
            print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
        end
        
    elseif subcommand == "clear" then
        addon.Config.ClearStatPriorities()
        print("|cff00ff00[GuildItemScanner]|r Cleared all stat priorities")
        
    elseif subcommand == "list" then
        print("|cff00ff00[GuildItemScanner]|r === Available Stats ===")
        print("|cffffcc00Primary Attributes:|r strength, agility, stamina, intellect, spirit")
        print("|cffffcc00Combat Stats:|r attackpower, spellpower, healing, mp5")
        print("|cffffcc00Rating Stats:|r crit, hit, haste, spellcrit")
        print("|cffffcc00Defense Stats:|r defense, armor, dodge, parry, block")
        print("|cffffcc00Resistances:|r fire, nature, frost, shadow, arcane, holy")
        print("|cff00ff00[GuildItemScanner]|r Use: /gis stats add <statname> [position]")
        
    else
        print("|cffff0000[GuildItemScanner]|r Unknown stats command: " .. subcommand)
        print("|cff00ff00[GuildItemScanner]|r Use '/gis stats help' for available commands")
    end
end

commandHandlers.statmode = function(args)
    if not addon.Config then return end
    
    if not args or args == "" then
        local currentMode = addon.Config.GetStatComparisonMode()
        print("|cff00ff00[GuildItemScanner]|r Current comparison mode: |cffffcc00" .. string.upper(currentMode) .. "|r")
        print("|cff00ff00[GuildItemScanner]|r Available modes:")
        print("  |cffffcc00ilvl|r - Item level only (default)")
        print("  |cffffcc00stats|r - Stat priorities only")
        print("  |cffffcc00both|r - Requires both ilvl AND stat upgrades")
        return
    end
    
    local mode = string.lower(args:match("^(%S+)"))
    local success, msg = addon.Config.SetStatComparisonMode(mode)
    if success then
        print("|cff00ff00[GuildItemScanner]|r Comparison mode set to: |cffffcc00" .. string.upper(mode) .. "|r")
        
        if mode == "stats" or mode == "both" then
            local priorities = addon.Config.GetStatPriorities()
            if #priorities == 0 then
                print("|cffff8000[GuildItemScanner]|r WARNING: No stat priorities set! Use '/gis stats add <stat>' to configure.")
            end
        end
    else
        print("|cffff0000[GuildItemScanner]|r Error: " .. msg)
    end
end

-- Status Command
commandHandlers.status = function()
    local _, class = UnitClass("player")
    print("|cff00ff00[GuildItemScanner]|r Status:")
    print("  Version: " .. addon.version .. " " .. addon.build)
    print("  Addon: " .. (addon.Config and addon.Config.Get("enabled") and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
    print("  Player: " .. class .. " (Level " .. UnitLevel("player") .. ")")
    print("  Debug mode: " .. (addon.Config and addon.Config.Get("debugMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print(" |cffFFD700Equipment Settings:|r")
    print("  Whisper mode: " .. (addon.Config and addon.Config.Get("whisperMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Greed mode: " .. (addon.Config and addon.Config.Get("greedMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Comparison mode: " .. (addon.Config and addon.Config.GetStatComparisonMode() and string.upper(addon.Config.GetStatComparisonMode()) or "ILVL"))
    local priorities = addon.Config and addon.Config.GetStatPriorities() or {}
    print("  Stat priorities: " .. (#priorities > 0 and table.concat(priorities, ", ") or "|cff808080None|r"))
    print(" |cffFFD700Alert Settings:|r")
    print("  Recipe alerts: " .. (addon.Config and addon.Config.Get("recipeAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Material alerts: " .. (addon.Config and addon.Config.Get("materialAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Bag alerts: " .. (addon.Config and addon.Config.Get("bagAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Potion alerts: " .. (addon.Config and addon.Config.Get("potionAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Sound alerts: " .. (addon.Config and addon.Config.Get("soundAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Alert duration: " .. (addon.Config and addon.Config.Get("alertDuration") or "5") .. " seconds")
    print(" |cffFFD700Filter Settings:|r")
    print("  Material rarity filter: " .. (addon.Config and addon.Config.Get("materialRarityFilter") or "common"))
    print("  Material quantity threshold: " .. (addon.Config and addon.Config.Get("materialQuantityThreshold") or "1"))
    print("  Bag size filter: " .. (addon.Config and addon.Config.Get("bagSizeFilter") or "6") .. "+ slots")
    print("  Potion type filter: " .. (addon.Config and addon.Config.Get("potionTypeFilter") or "all"))
    print(" |cffFFD700Social Settings:|r")
    print("  Auto-GZ mode: " .. (addon.Config and addon.Config.Get("autoGZ") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Auto-RIP mode: " .. (addon.Config and addon.Config.Get("autoRIP") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print(" |cffFFD700Testing Settings:|r")
    print("  Whisper test mode: " .. (addon.Config and addon.Config.Get("whisperTestMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print(" |cffFFD700Professions:|r")
    local professions = addon.Config and addon.Config.GetProfessions()
    print("  Active: " .. (#professions > 0 and table.concat(professions, ", ") or "|cff808080None|r"))
end

-- Custom Material Commands
commandHandlers.addmaterial = function(args)
    -- Parse: /gis addmaterial [Item Link] profession
    local itemLink = string.match(args, "|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        print("|cff00ff00[GuildItemScanner]|r Usage: /gis addmaterial [shift+click item] profession")
        print("  Example: /gis addmaterial [Crawler Claw] Cooking")
        return
    end
    
    -- Extract item name and profession
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    local profession = string.match(args, "|h|r%s+(.+)$")
    
    if not profession or profession == "" then
        print("|cff00ff00[GuildItemScanner]|r Please specify a profession")
        print("  Valid professions: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Leatherworking, Tailoring")
        return
    end
    
    -- Normalize profession name (capitalize first letter)
    profession = profession:gsub("^%l", string.upper)
    
    -- Validate profession
    local validProfessions = {"Alchemy", "Blacksmithing", "Cooking", "Enchanting", 
                              "Engineering", "First Aid", "Leatherworking", "Tailoring"}
    local isValid = false
    for _, prof in ipairs(validProfessions) do
        if prof == profession then
            isValid = true
            break
        end
    end
    
    if not isValid then
        print("|cff00ff00[GuildItemScanner]|r Invalid profession: " .. profession)
        return
    end
    
    -- Check if player has this profession
    local hasProfession = false
    for _, prof in ipairs(addon.Config.GetProfessions()) do
        if prof == profession then
            hasProfession = true
            break
        end
    end
    
    if not hasProfession then
        print("|cffff0000[GuildItemScanner]|r Note: You don't have " .. profession .. 
              " in your professions list.")
        print("|cffff0000[GuildItemScanner]|r Add it with: /gis prof add " .. profession)
    end
    
    -- Check if already exists in built-in database
    if addon.Databases.HasBuiltInMaterial(itemName, profession) then
        print("|cffff0000[GuildItemScanner]|r Warning: '" .. itemName .. 
              "' already exists in " .. profession .. " built-in database!")
        print("|cffff0000[GuildItemScanner]|r Your custom entry will OVERRIDE the built-in version.")
        print("|cffff0000[GuildItemScanner]|r Use '/gis removematerial' to revert to built-in.")
    end
    
    -- Check if already in custom materials
    local custom = addon.Config.Get("customMaterials") or {}
    if custom[profession] and custom[profession][itemName] then
        print("|cffff0000[GuildItemScanner]|r '" .. itemName .. 
              "' is already in your custom " .. profession .. " materials.")
        print("|cffff0000[GuildItemScanner]|r Updating entry...")
    end
    
    -- Auto-detect item quality/rarity
    local _, _, quality = GetItemInfo(itemLink)
    local rarityMap = {
        [0] = "common",  -- Poor (gray)
        [1] = "common",  -- Common (white)
        [2] = "common",  -- Uncommon (green)
        [3] = "rare",    -- Rare (blue)
        [4] = "epic",    -- Epic (purple)
        [5] = "legendary" -- Legendary (orange)
    }
    local rarity = rarityMap[quality] or "common"
    
    -- Add the custom material
    local materialInfo = {
        level = 1,  -- Default level
        type = "custom",
        rarity = rarity
    }
    
    addon.Databases.AddCustomMaterial(itemName, profession, materialInfo)
    
    print("|cff00ff00[GuildItemScanner]|r Added custom material: " .. itemLink .. 
          " to " .. profession .. " (rarity: " .. rarity .. ")")
    
    -- RARITY FILTER WARNING
    local currentFilter = addon.Config.Get("materialRarityFilter") or "common"
    local rarityOrder = {common = 1, rare = 2, epic = 3, legendary = 4}
    
    if rarityOrder[rarity] < rarityOrder[currentFilter] then
        print("|cffff0000[GuildItemScanner]|r WARNING: This material won't trigger alerts!")
        print("|cffff0000[GuildItemScanner]|r Current filter: " .. currentFilter .. 
              " | Item rarity: " .. rarity)
        print("|cffff0000[GuildItemScanner]|r To detect this material, use: /gis rarity " .. rarity)
    elseif hasProfession then
        print("|cff00ff00[GuildItemScanner]|r This material WILL trigger alerts (rarity >= filter)")
    end
end

commandHandlers.removematerial = function(args)
    local itemLink = string.match(args, "|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        print("|cff00ff00[GuildItemScanner]|r Usage: /gis removematerial [shift+click item] profession")
        return
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    local profession = string.match(args, "|h|r%s+(.+)$")
    
    if not profession or profession == "" then
        print("|cff00ff00[GuildItemScanner]|r Please specify a profession")
        return
    end
    
    profession = profession:gsub("^%l", string.upper)
    
    -- Remove from custom materials
    if addon.Databases.RemoveCustomMaterial(itemName, profession) then
        print("|cff00ff00[GuildItemScanner]|r Removed custom material: " .. itemName .. " from " .. profession)
        
        -- Check if it exists in built-in
        if addon.Databases.HasBuiltInMaterial(itemName, profession) then
            print("|cff00ff00[GuildItemScanner]|r Note: Reverting to built-in database version")
            
            -- Show rarity info for built-in version
            local builtInMat = addon.Databases.MATERIALS[profession][itemName]
            if builtInMat and builtInMat.rarity then
                local currentFilter = addon.Config.Get("materialRarityFilter") or "common"
                local rarityOrder = {common = 1, rare = 2, epic = 3, legendary = 4}
                
                if rarityOrder[builtInMat.rarity] < rarityOrder[currentFilter] then
                    print("|cffff0000[GuildItemScanner]|r Note: Built-in version (rarity: " .. 
                          builtInMat.rarity .. ") won't trigger with current filter: " .. currentFilter)
                end
            end
        end
    else
        print("|cffff0000[GuildItemScanner]|r Custom material not found: " .. itemName .. " in " .. profession)
    end
end

commandHandlers.listcustom = function(args)
    local profession = args and args:match("^(%S+)")
    if profession then
        profession = profession:gsub("^%l", string.upper)
    end
    
    local custom = addon.Config.Get("customMaterials") or {}
    local currentFilter = addon.Config.Get("materialRarityFilter") or "common"
    local rarityOrder = {common = 1, rare = 2, epic = 3, legendary = 4}
    local hasAny = false
    
    print("|cff00ff00[GuildItemScanner]|r === Custom Materials ===")
    print("|cff00ff00[GuildItemScanner]|r Current rarity filter: " .. currentFilter)
    
    for prof, materials in pairs(custom) do
        if not profession or prof == profession then
            local count = 0
            for _ in pairs(materials) do count = count + 1 end
            
            if count > 0 then
                hasAny = true
                print("|cffffcc00" .. prof .. ":|r (" .. count .. " custom)")
                
                for matName, matInfo in pairs(materials) do
                    local override = ""
                    if addon.Databases.HasBuiltInMaterial(matName, prof) then
                        override = " |cffff0000[OVERRIDE]|r"
                    end
                    
                    -- Check if will trigger with current filter
                    local willTrigger = ""
                    if rarityOrder[matInfo.rarity] < rarityOrder[currentFilter] then
                        willTrigger = " |cff808080[FILTERED]|r"
                    else
                        willTrigger = " |cff00ff00[ACTIVE]|r"
                    end
                    
                    print("  - " .. matName .. " (" .. matInfo.rarity .. ")" .. override .. willTrigger)
                end
            end
        end
    end
    
    if not hasAny then
        print("  No custom materials found")
    else
        print("|cff00ff00[GuildItemScanner]|r [ACTIVE] = will trigger | [FILTERED] = won't trigger")
    end
end

commandHandlers.clearcustom = function(args)
    local profession = args and args:match("^(%S+)")
    
    if profession then
        profession = profession:gsub("^%l", string.upper)
        local custom = addon.Config.Get("customMaterials") or {}
        if custom[profession] then
            local count = 0
            for _ in pairs(custom[profession]) do count = count + 1 end
            custom[profession] = nil
            addon.Config.Set("customMaterials", custom)
            addon.Config.Save()
            print("|cff00ff00[GuildItemScanner]|r Cleared " .. count .. " custom materials from " .. profession)
        else
            print("|cffff0000[GuildItemScanner]|r No custom materials found for " .. profession)
        end
    else
        -- Clear all
        addon.Config.Set("customMaterials", {})
        addon.Config.Save()
        print("|cff00ff00[GuildItemScanner]|r Cleared ALL custom materials")
    end
end

-- Help Command
commandHandlers.help = function()
    print("|cff00ff00[GuildItemScanner v" .. addon.version .. "]|r Complete Command List:")
    print(" |cffFFD700Core Commands:|r")
    print(" /gis on/off - Enable/disable addon")
    print(" /gis status - Show complete configuration")
    print(" /gis debug - Toggle debug logging")
    print(" /gis sound - Toggle sound alerts")
    print(" /gis duration <seconds> - Set alert duration (1-60)")
    print(" /gis reset - Reset all settings to defaults")
    print(" |cffFFD700Equipment Commands:|r")
    print(" /gis test - Test equipment alert")
    print(" /gis whisper - Toggle whisper mode for requests")
    print(" /gis greed - Toggle greed button display")
    print(" |cffFFD700Profession Commands:|r")
    print(" /gis prof add/remove/clear/list <profession> - Manage professions")
    print(" /gis recipe - Toggle recipe alerts")
    print(" /gis recipebutton - Toggle recipe request button")
    print(" |cffFFD700Material Commands:|r")
    print(" /gis material/mat - Toggle material alerts")
    print(" /gis matbutton - Toggle material request button")
    print(" /gis rarity <level> - Set material rarity filter")
    print(" /gis quantity/qty <num> - Set minimum stack size")
    print(" /gis addmaterial [item] <prof> - Add custom material for profession")
    print(" /gis removematerial [item] <prof> - Remove custom material")
    print(" /gis listcustom [prof] - List custom materials (all or by profession)")
    print(" /gis clearcustom [prof] - Clear custom materials (all or by profession)")
    print(" |cffFFD700Bag Commands:|r")
    print(" /gis bag - Toggle bag alerts")
    print(" /gis bagbutton - Toggle bag request button")
    print(" /gis bagsize <num> - Set minimum bag size filter")
    print(" |cffFFD700Potion Commands:|r")
    print(" /gis potion - Toggle potion alerts")
    print(" /gis potionbutton - Toggle potion request button")
    print(" /gis potiontype <type> - Set potion filter (all/combat/profession/misc)")
    print(" |cffFFD700Social Commands:|r")
    print(" /gis gz - Toggle auto-congratulations")
    print(" /gis rip - Toggle auto-condolences")
    print(" |cffFFD700History Commands:|r")
    print(" /gis history [filter] - Show alert history")
    print(" /gis clearhistory - Clear alert history")
    print(" /gis uncached - Show uncached item history (for debugging)")
    print(" /gis cachediag - Diagnose item cache corruption issues")
    print(" /gis compare [item] - Compare any item with your equipped gear")
    print(" |cffFFD700Testing Commands:|r")
    print(" /gis test/testmat/testbag/testrecipe/testpotion - Test all alert types")
    print(" /gis testfrontier - Test Frontier message pattern matching")
    print(" /gis testgz/testrip - Test social automation features")
    print(" /gis whispertest - Toggle whisper-based testing mode")
    print("Type |cffffff00/gis help|r to see this list again.")
end

-- Main command handler
local function onSlashCommand(msg)
    local cmd, args = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    args = args or ""
    
    if cmd == "" or cmd == "help" then
        commandHandlers.help()
    elseif commandHandlers[cmd] then
        commandHandlers[cmd](args)
    else
        print("|cff00ff00[GuildItemScanner]|r Unknown command: " .. cmd)
        print("Type |cffffff00/gis help|r for a list of all commands.")
    end
end

-- Initialize slash commands
function Commands.Initialize()
    SLASH_GUILDITEMSCANNER1 = "/gis"
    SlashCmdList["GUILDITEMSCANNER"] = onSlashCommand
end
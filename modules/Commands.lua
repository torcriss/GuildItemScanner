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
commandHandlers.gz = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("autoGZ")
        print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

commandHandlers.rip = function()
    if addon.Config then
        local enabled = addon.Config and addon.Config.Toggle("autoRIP")
        print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
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
                print(string.format("  ✓ %s = '%s' |cff00ff00(CORRECT)|r", itemLink, actualName))
            else
                print(string.format("  ✗ %s = '%s' |cffff0000(WRONG, expected '%s')|r", itemLink, actualName, expectedName))
            end
        else
            print(string.format("  ? %s = |cffff0000nil (NOT CACHED)|r", itemLink))
        end
    end
    
    print("|cff00ff00[GuildItemScanner]|r If cache is corrupted, try reloading UI (/reload) or restarting WoW.")
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
    print(" |cffFFD700Professions:|r")
    local professions = addon.Config and addon.Config.GetProfessions()
    print("  Active: " .. (#professions > 0 and table.concat(professions, ", ") or "|cff808080None|r"))
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
    print(" |cffFFD700Testing Commands:|r")
    print(" /gis test/testmat/testbag/testrecipe/testpotion - Test all alert types")
    print(" /gis testfrontier - Test Frontier message pattern matching")
    print(" /gis testgz/testrip - Test social automation features")
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
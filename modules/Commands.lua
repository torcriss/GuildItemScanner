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
        local enabled = addon.Config.Toggle("debugMode")
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

commandHandlers.sound = function()
    if addon.Config then
        local enabled = addon.Config.Toggle("soundAlert")
        print("|cff00ff00[GuildItemScanner]|r Sound alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    end
end

commandHandlers.duration = function(args)
    if not addon.Config then return end
    
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current alert duration: " .. addon.Config.Get("alertDuration") .. " seconds")
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
    local enabled = Config.Toggle("whisperMode")
    print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.greed = function()
    local enabled = Config.Toggle("greedMode")
    print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

-- Profession Commands
commandHandlers.prof = function(args)
    if args == "" then
        local professions = Config.GetProfessions()
        if #professions == 0 then
            print("|cff00ff00[GuildItemScanner]|r No professions set. Use /gis prof add <profession>")
        else
            print("|cff00ff00[GuildItemScanner]|r Your professions: " .. table.concat(professions, ", "))
        end
    else
        local subCmd, profession = args:match("^(%S+)%s*(.*)$")
        if subCmd == "add" and profession ~= "" then
            local success, result = Config.AddProfession(profession)
            if success then
                print("|cff00ff00[GuildItemScanner]|r Added profession: " .. profession)
            else
                print("|cff00ff00[GuildItemScanner]|r You already have " .. profession)
            end
        elseif subCmd == "remove" and profession ~= "" then
            local success, result = Config.RemoveProfession(profession)
            if success then
                print("|cff00ff00[GuildItemScanner]|r Removed profession: " .. profession)
            else
                print("|cff00ff00[GuildItemScanner]|r Profession not found: " .. profession)
            end
        elseif subCmd == "clear" then
            Config.ClearProfessions()
            print("|cff00ff00[GuildItemScanner]|r Cleared all professions")
        elseif subCmd == "list" then
            commandHandlers.prof("")
        else
            print("|cff00ff00[GuildItemScanner]|r Usage: /gis prof [add|remove|clear|list] <profession>")
        end
    end
end

commandHandlers.recipe = function()
    local enabled = Config.Toggle("recipeAlert")
    print("|cff00ff00[GuildItemScanner]|r Recipe alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.recipebutton = function()
    local enabled = Config.Toggle("recipeButton")
    print("|cff00ff00[GuildItemScanner]|r Recipe request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

-- Material Commands
commandHandlers.material = function()
    local enabled = Config.Toggle("materialAlert")
    print("|cff00ff00[GuildItemScanner]|r Material alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end
commandHandlers.mat = commandHandlers.material

commandHandlers.matbutton = function()
    local enabled = Config.Toggle("materialButton")
    print("|cff00ff00[GuildItemScanner]|r Material request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.rarity = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current rarity filter: " .. Config.Get("materialRarityFilter"))
        print("|cff00ff00[GuildItemScanner]|r Valid rarities: common, rare, epic, legendary")
    else
        local validRarities = {common = true, rare = true, epic = true, legendary = true}
        local rarity = args:lower()
        if validRarities[rarity] then
            Config.Set("materialRarityFilter", rarity)
            print("|cff00ff00[GuildItemScanner]|r Material rarity filter set to: " .. rarity)
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid rarity. Valid options: common, rare, epic, legendary")
        end
    end
end

commandHandlers.quantity = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current quantity threshold: " .. Config.Get("materialQuantityThreshold"))
    else
        local qty = tonumber(args)
        if qty and qty >= 1 and qty <= 1000 then
            Config.Set("materialQuantityThreshold", qty)
            print("|cff00ff00[GuildItemScanner]|r Material quantity threshold set to: " .. qty)
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid quantity. Must be between 1 and 1000")
        end
    end
end
commandHandlers.qty = commandHandlers.quantity

-- Bag Commands
commandHandlers.bag = function()
    local enabled = Config.Toggle("bagAlert")
    print("|cff00ff00[GuildItemScanner]|r Bag alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.bagbutton = function()
    local enabled = Config.Toggle("bagButton")
    print("|cff00ff00[GuildItemScanner]|r Bag request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.bagsize = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current bag size filter: " .. Config.Get("bagSizeFilter") .. "+ slots")
    else
        local size = tonumber(args)
        if size and size >= 6 and size <= 24 then
            Config.Set("bagSizeFilter", size)
            print("|cff00ff00[GuildItemScanner]|r Bag size filter set to: " .. size .. "+ slots")
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid bag size. Must be between 6 and 24")
        end
    end
end

-- Potion Commands
commandHandlers.potion = function()
    local enabled = Config.Toggle("potionAlert")
    print("|cff00ff00[GuildItemScanner]|r Potion alerts " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.potionbutton = function()
    local enabled = Config.Toggle("potionButton")
    print("|cff00ff00[GuildItemScanner]|r Potion request button " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.potiontype = function(args)
    if args == "" then
        print("|cff00ff00[GuildItemScanner]|r Current potion type filter: " .. Config.Get("potionTypeFilter"))
        print("|cff00ff00[GuildItemScanner]|r Valid types: all, combat, profession, misc")
    else
        local validTypes = {all = true, combat = true, profession = true, misc = true}
        local ptype = args:lower()
        if validTypes[ptype] then
            Config.Set("potionTypeFilter", ptype)
            print("|cff00ff00[GuildItemScanner]|r Potion type filter set to: " .. ptype)
        else
            print("|cff00ff00[GuildItemScanner]|r Invalid type. Valid options: all, combat, profession, misc")
        end
    end
end

-- Social Commands
commandHandlers.gz = function()
    local enabled = Config.Toggle("autoGZ")
    print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

commandHandlers.rip = function()
    local enabled = Config.Toggle("autoRIP")
    print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end

-- History Commands
commandHandlers.history = function(args)
    History.ShowHistory(args)
end

commandHandlers.clearhistory = function()
    History.ClearHistory()
    print("|cff00ff00[GuildItemScanner]|r History cleared")
end

-- Testing Commands
commandHandlers.testmat = function()
    Detection.TestMaterial()
end

commandHandlers.testbag = function()
    Detection.TestBag()
end

commandHandlers.testrecipe = function()
    Detection.TestRecipe()
end

commandHandlers.testpotion = function()
    Detection.TestPotion()
end

-- Status Command
commandHandlers.status = function()
    local _, class = UnitClass("player")
    print("|cff00ff00[GuildItemScanner]|r Status:")
    print("  Version: " .. addon.version .. " " .. addon.build)
    print("  Addon: " .. (Config.Get("enabled") and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
    print("  Player: " .. class .. " (Level " .. UnitLevel("player") .. ")")
    print("  Debug mode: " .. (Config.Get("debugMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print(" |cffFFD700Equipment Settings:|r")
    print("  Whisper mode: " .. (Config.Get("whisperMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Greed mode: " .. (Config.Get("greedMode") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print(" |cffFFD700Alert Settings:|r")
    print("  Recipe alerts: " .. (Config.Get("recipeAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Material alerts: " .. (Config.Get("materialAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Bag alerts: " .. (Config.Get("bagAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Potion alerts: " .. (Config.Get("potionAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Sound alerts: " .. (Config.Get("soundAlert") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Alert duration: " .. Config.Get("alertDuration") .. " seconds")
    print(" |cffFFD700Filter Settings:|r")
    print("  Material rarity filter: " .. Config.Get("materialRarityFilter"))
    print("  Material quantity threshold: " .. Config.Get("materialQuantityThreshold"))
    print("  Bag size filter: " .. Config.Get("bagSizeFilter") .. "+ slots")
    print("  Potion type filter: " .. Config.Get("potionTypeFilter"))
    print(" |cffFFD700Social Settings:|r")
    print("  Auto-GZ mode: " .. (Config.Get("autoGZ") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print("  Auto-RIP mode: " .. (Config.Get("autoRIP") and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    print(" |cffFFD700Professions:|r")
    local professions = Config.GetProfessions()
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
    print(" |cffFFD700Testing Commands:|r")
    print(" /gis test/testmat/testbag/testrecipe/testpotion - Test all alert types")
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
-- Config.lua - Configuration management for GuildItemScanner
local addonName, addon = ...
addon.Config = addon.Config or {}
local Config = addon.Config

-- Default configuration
local defaultConfig = {
    enabled = true,
    soundAlert = true,
    whisperMode = false,
    greedMode = true,
    recipeButton = true,
    alertDuration = 10,
    debugMode = false,
    autoGZ = false,
    autoRIP = false,
    
    -- Equipment settings
    recipeAlert = true,
    statComparisonMode = "ilvl",  -- "ilvl", "stats", or "both"
    statPriorities = {},  -- ordered array of stat names
    
    -- Material settings
    materialAlert = true,
    materialButton = true,
    materialRarityFilter = "common",
    materialQuantityThreshold = 5,
    
    -- Bag settings
    bagAlert = true,
    bagButton = true,
    bagSizeFilter = 6,
    
    -- Potion settings
    potionAlert = true,
    potionButton = true,
    potionTypeFilter = "all",
    
    -- Profession settings
    myProfessions = {},
    
    -- Custom materials (player-added)
    customMaterials = {},
    
    -- Custom social messages
    gzChance = 50,  -- percentage chance to send GZ
    ripChance = 60, -- percentage chance to send RIP
    customGzMessages = {},  -- custom GZ messages
    customRipMessages = {    -- custom RIP messages by level
        low = {},   -- levels 1-39
        mid = {},   -- levels 40-59
        high = {}   -- level 60
    },
    
    -- Sound settings
    soundDuration = 2,
    
    -- Testing settings
    whisperTestMode = false,
    
    -- Version tracking
    configVersion = "2.0"
}

local config = {}

-- Initialize config with defaults
for k, v in pairs(defaultConfig) do
    config[k] = v
end

function Config.Load()
    if not GuildItemScannerDB then
        GuildItemScannerDB = { 
            config = {}, 
            alertHistory = {}, 
            uncachedHistory = {},
            version = addon.version or "2.0"
        }
    end
    
    -- Load saved config, using defaults for missing values
    for k, v in pairs(defaultConfig) do
        if GuildItemScannerDB.config[k] == nil then
            GuildItemScannerDB.config[k] = v
        end
    end
    
    -- Copy to working config
    config = {}
    for k, v in pairs(GuildItemScannerDB.config) do
        config[k] = v
    end
    
    -- Ensure professions table exists
    config.myProfessions = config.myProfessions or {}
end

function Config.Save()
    if GuildItemScannerDB then
        GuildItemScannerDB.config = config
        GuildItemScannerDB.version = addon.version or "2.0"
    end
end

function Config.Get(key)
    return config[key]
end

function Config.Set(key, value)
    config[key] = value
    Config.Save()
end

function Config.Toggle(key)
    config[key] = not config[key]
    Config.Save()
    return config[key]
end

function Config.GetAll()
    return config
end

function Config.Reset()
    config = {}
    for k, v in pairs(defaultConfig) do
        config[k] = v
    end
    Config.Save()
end

function Config.AddProfession(profession)
    profession = profession:gsub("^%l", string.upper)
    
    for _, prof in ipairs(config.myProfessions) do
        if string.lower(prof) == string.lower(profession) then
            return false, "Already exists"
        end
    end
    
    table.insert(config.myProfessions, profession)
    Config.Save()
    return true, "Added"
end

function Config.RemoveProfession(profession)
    profession = profession:gsub("^%l", string.upper)
    
    for i, prof in ipairs(config.myProfessions) do
        if string.lower(prof) == string.lower(profession) then
            table.remove(config.myProfessions, i)
            Config.Save()
            return true, "Removed"
        end
    end
    return false, "Not found"
end

function Config.ClearProfessions()
    config.myProfessions = {}
    Config.Save()
end

function Config.GetProfessions()
    return config.myProfessions
end

function Config.HasProfession(profession)
    for _, prof in ipairs(config.myProfessions) do
        if string.lower(prof) == string.lower(profession) then
            return true
        end
    end
    return false
end

-- Custom GZ message functions
function Config.AddGzMessage(message)
    message = string.gsub(message, "^%s*(.-)%s*$", "%1") -- trim whitespace
    
    -- Validate message
    if string.len(message) == 0 then
        return false, "Message cannot be empty"
    end
    if string.len(message) > 50 then
        return false, "Message too long (max 50 characters)"
    end
    
    -- Check for duplicates
    for _, existingMsg in ipairs(config.customGzMessages) do
        if string.lower(existingMsg) == string.lower(message) then
            return false, "Message already exists"
        end
    end
    
    table.insert(config.customGzMessages, message)
    Config.Save()
    return true, "Added"
end

function Config.RemoveGzMessage(index)
    index = tonumber(index)
    if not index or index < 1 or index > #config.customGzMessages then
        return false, "Invalid index"
    end
    
    table.remove(config.customGzMessages, index)
    Config.Save()
    return true, "Removed"
end

function Config.ClearGzMessages()
    config.customGzMessages = {}
    Config.Save()
end

function Config.GetGzMessages()
    return config.customGzMessages
end

function Config.SetGzChance(chance)
    chance = tonumber(chance)
    if not chance or chance < 0 or chance > 100 then
        return false, "Chance must be 0-100"
    end
    
    config.gzChance = chance
    Config.Save()
    return true, "Set"
end

function Config.GetGzChance()
    return config.gzChance
end

-- Custom RIP message functions
function Config.AddRipMessage(level, message)
    level = string.lower(level)
    message = string.gsub(message, "^%s*(.-)%s*$", "%1") -- trim whitespace
    
    -- Validate level category
    if level ~= "low" and level ~= "mid" and level ~= "high" then
        return false, "Level must be: low (1-39), mid (40-59), or high (60)"
    end
    
    -- Validate message
    if string.len(message) == 0 then
        return false, "Message cannot be empty"
    end
    if string.len(message) > 50 then
        return false, "Message too long (max 50 characters)"
    end
    
    -- Check for duplicates in this level category
    for _, existingMsg in ipairs(config.customRipMessages[level]) do
        if string.lower(existingMsg) == string.lower(message) then
            return false, "Message already exists in " .. level .. " category"
        end
    end
    
    table.insert(config.customRipMessages[level], message)
    Config.Save()
    return true, "Added"
end

function Config.RemoveRipMessage(level, index)
    level = string.lower(level)
    index = tonumber(index)
    
    if level ~= "low" and level ~= "mid" and level ~= "high" then
        return false, "Level must be: low, mid, or high"
    end
    
    if not index or index < 1 or index > #config.customRipMessages[level] then
        return false, "Invalid index"
    end
    
    table.remove(config.customRipMessages[level], index)
    Config.Save()
    return true, "Removed"
end

function Config.ClearRipMessages(level)
    if level then
        level = string.lower(level)
        if level ~= "low" and level ~= "mid" and level ~= "high" then
            return false, "Level must be: low, mid, or high"
        end
        config.customRipMessages[level] = {}
    else
        -- Clear all levels
        config.customRipMessages = {low = {}, mid = {}, high = {}}
    end
    Config.Save()
    return true, "Cleared"
end

function Config.GetRipMessages(level)
    if level then
        level = string.lower(level)
        return config.customRipMessages[level] or {}
    else
        return config.customRipMessages
    end
end

function Config.SetRipChance(chance)
    chance = tonumber(chance)
    if not chance or chance < 0 or chance > 100 then
        return false, "Chance must be 0-100"
    end
    
    config.ripChance = chance
    Config.Save()
    return true, "Set"
end

function Config.GetRipChance()
    return config.ripChance
end

-- Stat Priority Management Functions
function Config.AddStatPriority(stat, position)
    stat = string.lower(stat:gsub("^%s*(.-)%s*$", "%1")) -- trim and lowercase
    
    -- Validate stat name
    local validStats = {
        strength = true, agility = true, stamina = true, intellect = true, spirit = true,
        attackpower = true, spellpower = true, healing = true, mp5 = true,
        crit = true, hit = true, haste = true, defense = true, armor = true,
        dodge = true, parry = true, block = true, spellcrit = true,
        fire = true, nature = true, shadow = true, frost = true, arcane = true, holy = true
    }
    
    if not validStats[stat] then
        return false, "Invalid stat. Valid stats: strength, agility, stamina, intellect, spirit, attackpower, spellpower, healing, mp5, crit, hit, haste, defense, armor, dodge, parry, block, spellcrit, fire, nature, shadow, frost, arcane, holy"
    end
    
    -- Check if stat already exists
    for i, existingStat in ipairs(config.statPriorities) do
        if existingStat == stat then
            return false, "Stat already in priorities"
        end
    end
    
    -- Add at position or end
    if position then
        position = tonumber(position)
        if position and position >= 1 and position <= (#config.statPriorities + 1) then
            table.insert(config.statPriorities, position, stat)
        else
            return false, "Invalid position"
        end
    else
        table.insert(config.statPriorities, stat)
    end
    
    Config.Save()
    return true, "Added"
end

function Config.RemoveStatPriority(stat)
    stat = string.lower(stat:gsub("^%s*(.-)%s*$", "%1"))
    
    for i, existingStat in ipairs(config.statPriorities) do
        if existingStat == stat then
            table.remove(config.statPriorities, i)
            Config.Save()
            return true, "Removed"
        end
    end
    return false, "Stat not found in priorities"
end

function Config.ClearStatPriorities()
    config.statPriorities = {}
    Config.Save()
end

function Config.GetStatPriorities()
    return config.statPriorities
end

function Config.MoveStatPriority(stat, newPosition)
    stat = string.lower(stat:gsub("^%s*(.-)%s*$", "%1"))
    newPosition = tonumber(newPosition)
    
    if not newPosition or newPosition < 1 or newPosition > #config.statPriorities then
        return false, "Invalid position"
    end
    
    -- Find current position
    local currentPos = nil
    for i, existingStat in ipairs(config.statPriorities) do
        if existingStat == stat then
            currentPos = i
            break
        end
    end
    
    if not currentPos then
        return false, "Stat not found in priorities"
    end
    
    -- Remove from current position and insert at new position
    local statName = table.remove(config.statPriorities, currentPos)
    table.insert(config.statPriorities, newPosition, statName)
    
    Config.Save()
    return true, "Moved"
end

function Config.SetStatComparisonMode(mode)
    local validModes = {ilvl = true, stats = true, both = true}
    if not validModes[mode] then
        return false, "Invalid mode. Valid modes: ilvl, stats, both"
    end
    
    config.statComparisonMode = mode
    Config.Save()
    return true, "Set"
end

function Config.GetStatComparisonMode()
    return config.statComparisonMode
end
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
    useStatPriority = false,
    statPriority = {},
    
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
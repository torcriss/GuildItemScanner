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
    alertDuration = 15,
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
    materialQuantityThreshold = 1,
    
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
    gzChance = 30,  -- percentage chance to send GZ
    ripChance = 30, -- percentage chance to send RIP
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
            profiles = {},
            currentProfile = nil,
            defaultProfile = nil,
            version = addon.version or "2.0"
        }
    end
    
    -- Initialize profile system if missing
    if not GuildItemScannerDB.profiles then
        GuildItemScannerDB.profiles = {}
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
    
    -- Auto-load default profile if set
    local defaultProfile = GuildItemScannerDB.defaultProfile
    if defaultProfile and GuildItemScannerDB.profiles[defaultProfile] then
        Config.LoadProfile(defaultProfile)
    end
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

-- Profile Management Functions

function Config.SaveProfile(name, description)
    if not name or name == "" then
        return false, "Profile name cannot be empty"
    end
    
    -- Sanitize profile name
    name = string.gsub(name, "[^%w%s%-_]", "")
    name = string.gsub(name, "^%s*(.-)%s*$", "%1") -- trim whitespace
    
    if string.len(name) == 0 then
        return false, "Profile name must contain valid characters"
    end
    if string.len(name) > 30 then
        return false, "Profile name too long (max 30 characters)"
    end
    
    -- Create profile data
    local profileData = {
        config = {},
        description = description or "",
        created = time(),
        lastUpdated = time(),
        character = UnitName("player"),
        realm = GetRealmName(),
        configVersion = defaultConfig.configVersion
    }
    
    -- Copy current config
    for k, v in pairs(config) do
        if type(v) == "table" then
            profileData.config[k] = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "table" then
                    profileData.config[k][k2] = {}
                    for k3, v3 in pairs(v2) do
                        profileData.config[k][k2][k3] = v3
                    end
                else
                    profileData.config[k][k2] = v2
                end
            end
        else
            profileData.config[k] = v
        end
    end
    
    -- Save profile
    GuildItemScannerDB.profiles[name] = profileData
    GuildItemScannerDB.currentProfile = name
    
    Config.Save()
    return true, "Profile saved"
end

function Config.LoadProfile(name)
    if not name or name == "" then
        return false, "Profile name cannot be empty"
    end
    
    local profile = GuildItemScannerDB.profiles[name]
    if not profile then
        return false, "Profile not found: " .. name
    end
    
    -- Load profile config
    config = {}
    for k, v in pairs(profile.config) do
        if type(v) == "table" then
            config[k] = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "table" then
                    config[k][k2] = {}
                    for k3, v3 in pairs(v2) do
                        config[k][k2][k3] = v3
                    end
                else
                    config[k][k2] = v2
                end
            end
        else
            config[k] = v
        end
    end
    
    -- Update current profile
    GuildItemScannerDB.currentProfile = name
    
    Config.Save()
    return true, "Profile loaded"
end

function Config.DeleteProfile(name)
    if not name or name == "" then
        return false, "Profile name cannot be empty"
    end
    
    if not GuildItemScannerDB.profiles[name] then
        return false, "Profile not found: " .. name
    end
    
    -- Don't delete if it's the current profile
    if GuildItemScannerDB.currentProfile == name then
        return false, "Cannot delete currently active profile"
    end
    
    -- Clear default if this was the default
    if GuildItemScannerDB.defaultProfile == name then
        GuildItemScannerDB.defaultProfile = nil
    end
    
    GuildItemScannerDB.profiles[name] = nil
    Config.Save()
    return true, "Profile deleted"
end

function Config.ListProfiles()
    local profiles = {}
    for name, profile in pairs(GuildItemScannerDB.profiles) do
        table.insert(profiles, {
            name = name,
            description = profile.description or "",
            created = profile.created or 0,
            lastUpdated = profile.lastUpdated or 0,
            character = profile.character or "Unknown",
            realm = profile.realm or "Unknown",
            isCurrent = (GuildItemScannerDB.currentProfile == name),
            isDefault = (GuildItemScannerDB.defaultProfile == name)
        })
    end
    
    -- Sort by name
    table.sort(profiles, function(a, b) return a.name < b.name end)
    
    return profiles
end

function Config.GetCurrentProfile()
    return GuildItemScannerDB.currentProfile
end

function Config.SetDefaultProfile(name)
    if name and name ~= "" then
        if not GuildItemScannerDB.profiles[name] then
            return false, "Profile not found: " .. name
        end
        GuildItemScannerDB.defaultProfile = name
    else
        GuildItemScannerDB.defaultProfile = nil
    end
    
    Config.Save()
    return true, "Default profile set"
end

function Config.GetDefaultProfile()
    return GuildItemScannerDB.defaultProfile
end

function Config.CopyProfile(sourceName, targetName, description)
    if not sourceName or sourceName == "" then
        return false, "Source profile name cannot be empty"
    end
    if not targetName or targetName == "" then
        return false, "Target profile name cannot be empty"
    end
    
    local sourceProfile = GuildItemScannerDB.profiles[sourceName]
    if not sourceProfile then
        return false, "Source profile not found: " .. sourceName
    end
    
    if GuildItemScannerDB.profiles[targetName] then
        return false, "Target profile already exists: " .. targetName
    end
    
    -- Sanitize target name
    targetName = string.gsub(targetName, "[^%w%s%-_]", "")
    targetName = string.gsub(targetName, "^%s*(.-)%s*$", "%1")
    
    if string.len(targetName) == 0 then
        return false, "Target profile name must contain valid characters"
    end
    if string.len(targetName) > 30 then
        return false, "Target profile name too long (max 30 characters)"
    end
    
    -- Deep copy source profile
    local newProfile = {
        config = {},
        description = description or sourceProfile.description or "",
        created = time(),
        lastUpdated = time(),
        character = UnitName("player"),
        realm = GetRealmName(),
        configVersion = sourceProfile.configVersion or defaultConfig.configVersion
    }
    
    -- Deep copy config
    for k, v in pairs(sourceProfile.config) do
        if type(v) == "table" then
            newProfile.config[k] = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "table" then
                    newProfile.config[k][k2] = {}
                    for k3, v3 in pairs(v2) do
                        newProfile.config[k][k2][k3] = v3
                    end
                else
                    newProfile.config[k][k2] = v2
                end
            end
        else
            newProfile.config[k] = v
        end
    end
    
    GuildItemScannerDB.profiles[targetName] = newProfile
    Config.Save()
    return true, "Profile copied"
end

function Config.ExportProfile(name)
    if not name or name == "" then
        return false, "Profile name cannot be empty"
    end
    
    local profile = GuildItemScannerDB.profiles[name]
    if not profile then
        return false, "Profile not found: " .. name
    end
    
    -- Create export data
    local exportData = {
        name = name,
        profile = profile,
        exportVersion = "1.0",
        exportedBy = UnitName("player") .. "-" .. GetRealmName(),
        exportedAt = time()
    }
    
    -- Serialize to string (basic serialization)
    local function serialize(t, depth)
        depth = depth or 0
        if depth > 10 then return "nil" end -- prevent infinite recursion
        
        if type(t) == "table" then
            local result = "{"
            local first = true
            for k, v in pairs(t) do
                if not first then result = result .. "," end
                first = false
                
                if type(k) == "string" then
                    result = result .. "[" .. string.format("%q", k) .. "]="
                else
                    result = result .. "[" .. tostring(k) .. "]="
                end
                result = result .. serialize(v, depth + 1)
            end
            return result .. "}"
        elseif type(t) == "string" then
            return string.format("%q", t)
        else
            return tostring(t)
        end
    end
    
    local serialized = serialize(exportData)
    local encoded = "GIS_PROFILE:" .. serialized
    
    return true, encoded
end

function Config.ImportProfile(importString)
    if not importString or importString == "" then
        return false, "Import string cannot be empty"
    end
    
    if not string.match(importString, "^GIS_PROFILE:") then
        return false, "Invalid import string format"
    end
    
    local dataString = string.sub(importString, 13) -- Remove "GIS_PROFILE:" prefix
    
    -- Deserialize (basic deserialization)
    local function deserialize(str)
        local func = loadstring("return " .. str)
        if func then
            return func()
        end
        return nil
    end
    
    local success, exportData = pcall(deserialize, dataString)
    if not success or not exportData then
        return false, "Failed to parse import string"
    end
    
    if not exportData.name or not exportData.profile then
        return false, "Invalid profile data in import string"
    end
    
    local profileName = exportData.name
    if GuildItemScannerDB.profiles[profileName] then
        return false, "Profile already exists: " .. profileName .. " (delete it first to import)"
    end
    
    -- Import the profile
    GuildItemScannerDB.profiles[profileName] = exportData.profile
    Config.Save()
    
    return true, "Profile imported: " .. profileName
end

function Config.ResetToDefaults()
    config = {}
    for k, v in pairs(defaultConfig) do
        config[k] = v
    end
    GuildItemScannerDB.currentProfile = nil
    Config.Save()
    return true, "Settings reset to defaults"
end
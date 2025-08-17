-- Config.lua - Configuration management for GuildItemScanner
local addonName, addon = ...
addon.Config = addon.Config or {}
local Config = addon.Config

-- Valid professions (must match the ones defined in Databases.lua)
local VALID_PROFESSIONS = {
    "Alchemy",
    "Blacksmithing", 
    "Cooking",
    "Enchanting",
    "Engineering",
    "First Aid",
    "Leatherworking",
    "Tailoring"
}

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
    
    -- Ensure DEFAULT profile exists
    Config.EnsureDefaultProfile()
    
    -- If no current profile, load DEFAULT
    if not GuildItemScannerDB.currentProfile then
        GuildItemScannerDB.currentProfile = "DEFAULT"
    end
    
    -- Load the current profile (DEFAULT or another)
    local currentProfile = GuildItemScannerDB.currentProfile
    if currentProfile and GuildItemScannerDB.profiles[currentProfile] then
        Config.LoadProfile(currentProfile)
    else
        -- Fallback to DEFAULT if current profile doesn't exist
        Config.LoadProfile("DEFAULT")
    end
    
    -- Auto-load default profile if set (for startup auto-load)
    local defaultProfile = GuildItemScannerDB.defaultProfile
    if defaultProfile and GuildItemScannerDB.profiles[defaultProfile] then
        Config.LoadProfile(defaultProfile)
    end
end

function Config.Save()
    if GuildItemScannerDB then
        GuildItemScannerDB.config = config
        GuildItemScannerDB.version = addon.version or "2.0"
        
        -- Always auto-save to current profile
        Config.AutoSaveProfile()
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
    
    -- Validate that profession is supported
    local isValidProfession = false
    for _, validProf in ipairs(VALID_PROFESSIONS) do
        if string.lower(validProf) == string.lower(profession) then
            isValidProfession = true
            profession = validProf  -- Use the canonical capitalization
            break
        end
    end
    
    if not isValidProfession then
        return false, "Invalid profession. Supported: " .. table.concat(VALID_PROFESSIONS, ", ")
    end
    
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
    
    -- Check if profile already exists to preserve metadata
    local existingProfile = GuildItemScannerDB.profiles[name]
    local profileData = {
        config = {},
        description = description or (existingProfile and existingProfile.description) or "",
        created = (existingProfile and existingProfile.created) or time(),
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
    
    -- Cannot delete DEFAULT profile
    if name == "DEFAULT" then
        return false, "Cannot delete DEFAULT profile"
    end
    
    if not GuildItemScannerDB.profiles[name] then
        return false, "Profile not found: " .. name
    end
    
    -- If deleting the current profile, load DEFAULT
    if GuildItemScannerDB.currentProfile == name then
        Config.LoadProfile("DEFAULT")
    end
    
    -- Clear default if this was the default
    if GuildItemScannerDB.defaultProfile == name then
        GuildItemScannerDB.defaultProfile = nil
    end
    
    GuildItemScannerDB.profiles[name] = nil
    
    -- Check if only DEFAULT profile remains
    local profileCount = 0
    for _ in pairs(GuildItemScannerDB.profiles) do
        profileCount = profileCount + 1
    end
    
    local message = "Profile deleted"
    if profileCount == 1 then -- Only DEFAULT remains
        message = message .. " (DEFAULT profile loaded)"
    end
    
    Config.Save()
    return true, message
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

function Config.AutoSaveProfile()
    local currentProfile = GuildItemScannerDB.currentProfile or "DEFAULT"
    
    -- Ensure the current profile exists
    if not GuildItemScannerDB.profiles[currentProfile] then
        -- If current profile doesn't exist, use DEFAULT
        currentProfile = "DEFAULT"
        GuildItemScannerDB.currentProfile = currentProfile
        Config.EnsureDefaultProfile()
    end
    
    -- Directly update the profile without calling SaveProfile (to avoid circular dependency)
    local existingProfile = GuildItemScannerDB.profiles[currentProfile]
    if existingProfile then
        -- Update the profile's config section with current settings
        existingProfile.config = {}
        for k, v in pairs(config) do
            existingProfile.config[k] = v
        end
        existingProfile.lastUpdated = time()
        return true, "Auto-saved to " .. currentProfile
    else
        return false, "Auto-save failed: Profile not found"
    end
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

function Config.EnsureDefaultProfile()
    -- Create DEFAULT profile if it doesn't exist
    if not GuildItemScannerDB.profiles["DEFAULT"] then
        local defaultProfileData = {
            config = {},
            description = "Factory default settings",
            created = time(),
            lastUpdated = time(),
            character = "System",
            realm = "Default",
            configVersion = defaultConfig.configVersion
        }
        
        -- Copy default config
        for k, v in pairs(defaultConfig) do
            if type(v) == "table" then
                defaultProfileData.config[k] = {}
                for k2, v2 in pairs(v) do
                    if type(v2) == "table" then
                        defaultProfileData.config[k][k2] = {}
                        for k3, v3 in pairs(v2) do
                            defaultProfileData.config[k][k2][k3] = v3
                        end
                    else
                        defaultProfileData.config[k][k2] = v2
                    end
                end
            else
                defaultProfileData.config[k] = v
            end
        end
        
        GuildItemScannerDB.profiles["DEFAULT"] = defaultProfileData
    end
end

function Config.ResetToDefaults()
    -- Reset DEFAULT profile to factory settings
    Config.EnsureDefaultProfile()
    local defaultProfileData = GuildItemScannerDB.profiles["DEFAULT"]
    defaultProfileData.config = {}
    defaultProfileData.lastUpdated = time()
    
    -- Copy factory defaults to DEFAULT profile
    for k, v in pairs(defaultConfig) do
        if type(v) == "table" then
            defaultProfileData.config[k] = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "table" then
                    defaultProfileData.config[k][k2] = {}
                    for k3, v3 in pairs(v2) do
                        defaultProfileData.config[k][k2][k3] = v3
                    end
                else
                    defaultProfileData.config[k][k2] = v2
                end
            end
        else
            defaultProfileData.config[k] = v
        end
    end
    
    -- Delete all other profiles (keep only DEFAULT)
    local profilesToDelete = {}
    for name, _ in pairs(GuildItemScannerDB.profiles) do
        if name ~= "DEFAULT" then
            table.insert(profilesToDelete, name)
        end
    end
    
    for _, name in ipairs(profilesToDelete) do
        GuildItemScannerDB.profiles[name] = nil
    end
    
    -- Load DEFAULT profile
    GuildItemScannerDB.currentProfile = "DEFAULT"
    GuildItemScannerDB.defaultProfile = nil
    
    -- Set current config to DEFAULT
    config = {}
    for k, v in pairs(defaultProfileData.config) do
        config[k] = v
    end
    
    Config.Save()
    return true, "DEFAULT profile reset to factory settings, all other profiles deleted"
end
-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Monitors guild chat for BoE equipment upgrades and alerts when items are upgrades

local addonName, addon = ...
addon.config = {
    soundAlert = true,
    whisperMode = false,
    greedMode = true,
    alertDuration = 10,
    debugMode = false,
    autoGZ = false,  -- Auto-congratulations for achievements
    autoRIP = false,  -- Auto-RIP for deaths
    recipeAlert = true,  -- Alert for profession recipes
    myProfessions = {},  -- Player's professions
    statPriority = {},  -- Stat priorities for gear evaluation
    useStatPriority = false  -- Whether to use stat priority instead of ilvl
}

local MAX_HISTORY = 20
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5

local retryQueue = {}
addon.alertHistory = {}
addon.uncachedHistory = {}

-- Alert Frame
local alertFrame = CreateFrame("Frame", "GuildItemScannerAlert", UIParent, "BackdropTemplate")
alertFrame:SetSize(600, 120)
alertFrame:SetPoint("TOP", 0, -200)
alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
alertFrame:SetBackdropColor(0, 0, 0, 0.9)
alertFrame:EnableMouse(true)
alertFrame:SetMovable(true)
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", alertFrame.StartMoving)
alertFrame:SetScript("OnDragStop", alertFrame.StopMovingOrSizing)
alertFrame:Hide()

-- Alert text
local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertText:SetPoint("TOP", 0, -25)
alertText:SetWidth(580)
alertText:SetJustifyH("CENTER")

-- Greed button
local greedButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
greedButton:SetSize(100, 25)
greedButton:SetPoint("BOTTOM", 0, 15)
greedButton:SetText("Greed!")

-- Close button
local closeButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() alertFrame:Hide() end)

-- Alert management
local currentAlert = nil

local SLOT_MAPPING = {
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_HEAD = "head",
    INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_BODY = "shirt",
    INVTYPE_CHEST = "chest", INVTYPE_WAIST = "waist", INVTYPE_LEGS = "legs",
    INVTYPE_FEET = "feet", INVTYPE_WRIST = "wrist", INVTYPE_HAND = "hands",
    INVTYPE_CLOAK = "back", INVTYPE_WEAPON = "main hand", INVTYPE_SHIELD = "off hand",
    INVTYPE_2HWEAPON = "two-hand", INVTYPE_WEAPONMAINHAND = "main hand",
    INVTYPE_WEAPONOFFHAND = "off hand", INVTYPE_HOLDABLE = "off hand",
    INVTYPE_RANGED = "ranged", INVTYPE_THROWN = "ranged",
    INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_RELIC = "ranged", INVTYPE_TABARD = "tabard"
}

local SLOT_ID_MAPPING = {
    INVTYPE_FINGER = 11, INVTYPE_TRINKET = 13, INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
    INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16, INVTYPE_SHIELD = 17,
    INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE = 17, INVTYPE_RANGED = 18, INVTYPE_THROWN = 18,
    INVTYPE_RANGEDRIGHT = 18, INVTYPE_RELIC = 18, INVTYPE_TABARD = 19
}

-- Class armor restrictions
local CLASS_ARMOR_RESTRICTIONS = {
    WARRIOR = { Cloth = true, Leather = true, Mail = true, Plate = true },
    PALADIN = { Cloth = true, Leather = true, Mail = true, Plate = true },
    HUNTER = { Cloth = true, Leather = true, Mail = true },
    ROGUE = { Cloth = true, Leather = true },
    PRIEST = { Cloth = true },
    SHAMAN = { Cloth = true, Leather = true, Mail = true },
    MAGE = { Cloth = true },
    WARLOCK = { Cloth = true },
    DRUID = { Cloth = true, Leather = true }
}

-- Weapon restrictions by class
local CLASS_WEAPON_RESTRICTIONS = {
    WARRIOR = { 
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true,
        ["Fist Weapons"] = true, ["Shields"] = true, ["Bows"] = true,
        ["Crossbows"] = true, ["Guns"] = true, ["Thrown"] = true
    },
    PALADIN = {
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Polearms"] = true, ["Shields"] = true
    },
    HUNTER = {
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
        ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true,
        ["Fist Weapons"] = true, ["Bows"] = true, ["Crossbows"] = true,
        ["Guns"] = true, ["Thrown"] = true
    },
    ROGUE = {
        ["One-Handed Swords"] = true, ["One-Handed Maces"] = true,
        ["Daggers"] = true, ["Fist Weapons"] = true, ["Bows"] = true,
        ["Crossbows"] = true, ["Guns"] = true, ["Thrown"] = true
    },
    PRIEST = {
        ["One-Handed Maces"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true
    },
    SHAMAN = {
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Staves"] = true, ["Daggers"] = true, ["Fist Weapons"] = true,
        ["Shields"] = true
    },
    MAGE = {
        ["One-Handed Swords"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true
    },
    WARLOCK = {
        ["One-Handed Swords"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true
    },
    DRUID = {
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true,
        ["Fist Weapons"] = true
    }
}

local function LoadSavedVariables()
    GuildItemScannerDB = GuildItemScannerDB or {
        config = {
            soundAlert = true,
            whisperMode = false,
            greedMode = true,
            alertDuration = 10,
            debugMode = false,
            autoGZ = false,
            autoRIP = false,
            recipeAlert = true,
            myProfessions = {}
        },
        alertHistory = {},
        uncachedHistory = {}
    }
    
    -- Ensure all config fields exist
    addon.config = GuildItemScannerDB.config
    addon.config.myProfessions = addon.config.myProfessions or {}
    addon.config.autoGZ = addon.config.autoGZ or false
    addon.config.autoRIP = addon.config.autoRIP or false
    addon.config.recipeAlert = addon.config.recipeAlert ~= false  -- Default to true
    addon.config.statPriority = addon.config.statPriority or {}
    addon.config.useStatPriority = addon.config.useStatPriority or false
    
    addon.alertHistory = GuildItemScannerDB.alertHistory
    addon.uncachedHistory = GuildItemScannerDB.uncachedHistory
end

-- Stat patterns for Classic WoW
local STAT_PATTERNS = {
    -- Primary stats
    ["(%d+) Strength"] = "strength",
    ["(%d+) Agility"] = "agility",
    ["(%d+) Stamina"] = "stamina",
    ["(%d+) Intellect"] = "intellect",
    ["(%d+) Spirit"] = "spirit",
    
    -- Secondary stats
    ["(%d+) Attack Power"] = "attackpower",
    ["(%d+) Spell Power"] = "spellpower",
    ["(%d+) Healing"] = "healing",
    ["(%d+) Spell Damage"] = "spelldamage",
    ["Improves your chance to get a critical strike by (%d+)%%"] = "crit",
    ["Improves your chance to hit by (%d+)%%"] = "hit",
    ["(%d+) Defense Rating"] = "defense",
    ["(%d+) Dodge Rating"] = "dodge",
    ["(%d+) Parry Rating"] = "parry",
    ["(%d+) Block Rating"] = "block",
    
    -- Resistances
    ["(%d+) Fire Resistance"] = "fireres",
    ["(%d+) Nature Resistance"] = "natureres",
    ["(%d+) Frost Resistance"] = "frostres",
    ["(%d+) Shadow Resistance"] = "shadowres",
    ["(%d+) Arcane Resistance"] = "arcaneres",
    
    -- All stats
    ["%+(%d+) All Stats"] = "allstats",
    ["%+(%d+) to All Stats"] = "allstats"
}

-- Function to get item stats
local function getItemStats(itemLink)
    local stats = {}
    
    -- Create a tooltip to scan
    local scanTip = CreateFrame("GameTooltip", "GIScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink(itemLink)
    
    -- Scan tooltip lines
    for i = 1, scanTip:NumLines() do
        local text = _G["GIScanTooltipTextLeft" .. i]:GetText()
        if text then
            -- Check each stat pattern
            for pattern, statName in pairs(STAT_PATTERNS) do
                local value = string.match(text, pattern)
                if value then
                    value = tonumber(value)
                    if statName == "allstats" then
                        -- Add to all primary stats
                        stats.strength = (stats.strength or 0) + value
                        stats.agility = (stats.agility or 0) + value
                        stats.stamina = (stats.stamina or 0) + value
                        stats.intellect = (stats.intellect or 0) + value
                        stats.spirit = (stats.spirit or 0) + value
                    else
                        stats[statName] = (stats[statName] or 0) + value
                    end
                end
            end
        end
    end
    
    scanTip:Hide()
    return stats
end

-- Function to calculate stat score based on priorities
local function calculateStatScore(stats)
    local score = 0
    for stat, value in pairs(stats) do
        local priority = addon.config.statPriority[stat]
        if priority and priority > 0 then
            score = score + (value * priority)
        end
    end
    return score
end

-- Function to compare items by stats
local function compareItemsByStats(newItemLink, equippedItemLink)
    if not equippedItemLink then
        return true, 0  -- No item equipped, new item is upgrade
    end
    
    local newStats = getItemStats(newItemLink)
    local equippedStats = getItemStats(equippedItemLink)
    
    local newScore = calculateStatScore(newStats)
    local equippedScore = calculateStatScore(equippedStats)
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r New item score: %.1f, Equipped score: %.1f", newScore, equippedScore))
    end
    
    return newScore > equippedScore, newScore - equippedScore
end

local function getEquippedItemLevel(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if not itemLink then return 0 end
    local _, _, _, itemLevel = GetItemInfo(itemLink)
    return itemLevel or 0
end

local function canPlayerUseItem(itemLink)
    local _, class = UnitClass("player")
    local _, _, _, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    
    if addon.config.debugMode then
        local slotName = SLOT_MAPPING[itemEquipLoc] or itemEquipLoc or "unknown"
        print(string.format("|cff00ff00[GIS Debug]|r %s %s (%s)", 
            itemSubType or "Unknown", slotName, class))
    end
    
    -- Check armor restrictions
    local isArmor = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_SHOULDER" or
        itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_WAIST" or
        itemEquipLoc == "INVTYPE_LEGS" or itemEquipLoc == "INVTYPE_FEET" or
        itemEquipLoc == "INVTYPE_WRIST" or itemEquipLoc == "INVTYPE_HAND" or
        itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_BODY"
    )
    
    if isArmor and itemSubType then
        local classRestrictions = CLASS_ARMOR_RESTRICTIONS[class]
        if classRestrictions and not classRestrictions[itemSubType] then
            if addon.config.debugMode then
                print(string.format("|cff00ff00[GIS Debug]|r Cannot use: %s armor", itemSubType))
            end
            return false
        end
    end
    
    -- Check weapon restrictions
    local isWeapon = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" or
        itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
        itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or
        itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_SHIELD"
    )
    
    if isWeapon and itemSubType then
        local classWeapons = CLASS_WEAPON_RESTRICTIONS[class]
        if classWeapons and not classWeapons[itemSubType] then
            if addon.config.debugMode then
                print(string.format("|cff00ff00[GIS Debug]|r Cannot use: %s", itemSubType))
            end
            return false
        end
    end
    
    -- Items like rings, trinkets, necks, etc. can be used by all classes
    return true
end

local function isItemUpgrade(itemLink)
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Checking: %s", itemLink))
    end
    
    -- First check if the player can even use this item
    if not canPlayerUseItem(itemLink) then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Rejected: |cffff0000Wrong class|r"))
        end
        return false
    end

    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not (itemLevel and itemEquipLoc) then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Missing item info"))
        end
        return false
    end

    -- Determine which slots to check
    local slotsToCheck = {}
    if itemEquipLoc == "INVTYPE_FINGER" then
        slotsToCheck = {11, 12}
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
        slotsToCheck = {13, 14}
    else
        local slot = SLOT_ID_MAPPING[itemEquipLoc]
        if slot then
            slotsToCheck = {slot}
        end
    end

    if #slotsToCheck == 0 then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Invalid slot: %s", itemEquipLoc or "nil"))
        end
        return false
    end

    -- Use stat priority if enabled and configured
    if addon.config.useStatPriority and next(addon.config.statPriority) then
        -- Check against each possible slot
        for _, slot in ipairs(slotsToCheck) do
            local equippedLink = GetInventoryItemLink("player", slot)
            local isUpgrade, scoreDiff = compareItemsByStats(itemLink, equippedLink)
            
            if isUpgrade then
                if addon.config.debugMode then
                    print(string.format("|cff00ff00[GIS Debug]|r Stat score +%.1f |cffa335eeUPGRADE!|r", scoreDiff))
                end
                return true, scoreDiff
            end
        end
        
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Not a stat upgrade"))
        end
        return false
    else
        -- Original item level based comparison
        local lowestEquippedLevel = 999
        for _, slot in ipairs(slotsToCheck) do
            local equippedLevel = getEquippedItemLevel(slot)
            if equippedLevel < lowestEquippedLevel then
                lowestEquippedLevel = equippedLevel
            end
        end
        
        if addon.config.debugMode then
            if itemLevel > lowestEquippedLevel then
                print(string.format("|cff00ff00[GIS Debug]|r ilvl %d vs %d |cffa335eeUPGRADE!|r", itemLevel, lowestEquippedLevel))
            else
                print(string.format("|cff00ff00[GIS Debug]|r ilvl %d vs %d", itemLevel, lowestEquippedLevel))
            end
        end
        return itemLevel > lowestEquippedLevel, itemLevel - lowestEquippedLevel
    end
end

local function addToHistory(itemLink, playerName)
    table.insert(addon.alertHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        type = "Equipment",
        status = "POSTED"
    })
    while #addon.alertHistory > MAX_HISTORY do
        table.remove(addon.alertHistory)
    end
end

-- Greed button click handler
greedButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "I'll take that " .. currentAlert.itemLink .. "! Thanks!"
        if addon.config.whisperMode then
            SendChatMessage(msg, "WHISPER", nil, currentAlert.playerName)
            print("|cff00ff00[GuildItemScanner]|r Whispered to " .. currentAlert.playerName)
        else
            SendChatMessage(msg, "GUILD")
            print("|cff00ff00[GuildItemScanner]|r Sent greed message to guild")
        end
        alertFrame:Hide()
    end
end)

local function showAlert(itemLink, playerName)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
    
    addToHistory(itemLink, playerName)

    -- Get upgrade info based on current mode
    local upgradeText, detailText
    if addon.config.useStatPriority and next(addon.config.statPriority) then
        -- Stat-based evaluation
        local isUpgrade, scoreDiff = isItemUpgrade(itemLink)
        upgradeText = string.format("+%.1f stat score upgrade: %s", scoreDiff, itemLink)
        
        -- Show which stats make it an upgrade
        local stats = getItemStats(itemLink)
        local statList = {}
        for stat, value in pairs(stats) do
            if addon.config.statPriority[stat] and addon.config.statPriority[stat] > 0 then
                table.insert(statList, string.format("%s: %d (x%.1f)", stat, value, addon.config.statPriority[stat]))
            end
        end
        detailText = string.format("From: %s (%s)", playerName, #statList > 0 and table.concat(statList, ", ") or "no priority stats")
    else
        -- Item level based evaluation
        local equippedLevel = 0
        if itemEquipLoc == "INVTYPE_FINGER" then
            equippedLevel = math.min(getEquippedItemLevel(11), getEquippedItemLevel(12))
        elseif itemEquipLoc == "INVTYPE_TRINKET" then
            equippedLevel = math.min(getEquippedItemLevel(13), getEquippedItemLevel(14))
        else
            equippedLevel = getEquippedItemLevel(SLOT_ID_MAPPING[itemEquipLoc] or 1)
        end
        
        local ilvlDiff = itemLevel - equippedLevel
        upgradeText = string.format("+%d ilvl upgrade: %s", ilvlDiff, itemLink)
        detailText = string.format("From: %s (%d>%d %s)", playerName, itemLevel, equippedLevel, slot)
    end

    -- Print to chat
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", upgradeText))
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", detailText))

    -- Show alert frame
    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        itemLevel = itemLevel,
        slot = slot
    }
    
    if addon.config.useStatPriority and next(addon.config.statPriority) then
        alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00%s|r", 
            playerName, itemLink, detailText))
    else
        alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00Item level %d (%s)|r", 
            playerName, itemLink, itemLevel or 0, slot))
    end
    
    -- Show or hide greed button based on config
    if addon.config.greedMode then
        greedButton:Show()
    else
        greedButton:Hide()
    end
    
    alertFrame:Show()
    
    if addon.config.soundAlert then
        PlaySound(3332)
    end
    
    -- Auto-hide after configured duration
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
        end
    end)
end

local function extractItemLinks(message)
    local items = {}
    for itemLink in string.gmatch(message, "|c%x+|Hitem:.-|h%[.-%]|h|r") do
        table.insert(items, itemLink)
    end
    return items
end

local function addToUncachedHistory(itemLink, playerName, message)
    table.insert(addon.uncachedHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        message = message:sub(1, 50)
    })
    while #addon.uncachedHistory > MAX_HISTORY do
        table.remove(addon.uncachedHistory)
    end
end

local function retryUncachedItems()
    if #retryQueue == 0 then return end
    local retryEntry = table.remove(retryQueue, 1)
    if retryEntry.retryCount >= MAX_RETRIES then
        return
    end
    retryEntry.retryCount = retryEntry.retryCount + 1
    processItemLink(retryEntry.itemLink, retryEntry.playerName, true)
end

function processItemLink(itemLink, playerName, skipCooldown)
    if not itemLink or not playerName then return end

    local itemName, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName then
        table.insert(retryQueue, { itemLink = itemLink, playerName = playerName, retryCount = 0 })
        addToUncachedHistory(itemLink, playerName, "Waiting for item info cache...")
        C_Timer.After(RETRY_DELAY, retryUncachedItems)
        return
    end

    if bindType == 1 then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Rejected: |cffff0000BoP|r"))
        end
        return
    end

    if isItemUpgrade(itemLink) then
        showAlert(itemLink, playerName)
    elseif addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Rejected: |cffff0000Not upgrade|r"))
    end
end

-- Stat patterns for Classic WoW
local STAT_PATTERNS = {
    -- Primary stats
    ["(%d+) Strength"] = "strength",
    ["(%d+) Agility"] = "agility",
    ["(%d+) Stamina"] = "stamina",
    ["(%d+) Intellect"] = "intellect",
    ["(%d+) Spirit"] = "spirit",
    
    -- Secondary stats
    ["(%d+) Attack Power"] = "attackpower",
    ["(%d+) Spell Power"] = "spellpower",
    ["(%d+) Healing"] = "healing",
    ["(%d+) Spell Damage"] = "spelldamage",
    ["Improves your chance to get a critical strike by (%d+)%%"] = "crit",
    ["Improves your chance to hit by (%d+)%%"] = "hit",
    ["(%d+) Defense Rating"] = "defense",
    ["(%d+) Dodge Rating"] = "dodge",
    ["(%d+) Parry Rating"] = "parry",
    ["(%d+) Block Rating"] = "block",
    
    -- Resistances
    ["(%d+) Fire Resistance"] = "fireres",
    ["(%d+) Nature Resistance"] = "natureres",
    ["(%d+) Frost Resistance"] = "frostres",
    ["(%d+) Shadow Resistance"] = "shadowres",
    ["(%d+) Arcane Resistance"] = "arcaneres",
    
    -- All stats
    ["%+(%d+) All Stats"] = "allstats",
    ["%+(%d+) to All Stats"] = "allstats"
}

-- Function to get item stats
local function getItemStats(itemLink)
    local stats = {}
    
    -- Create a tooltip to scan
    local scanTip = CreateFrame("GameTooltip", "GIScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink(itemLink)
    
    -- Scan tooltip lines
    for i = 1, scanTip:NumLines() do
        local text = _G["GIScanTooltipTextLeft" .. i]:GetText()
        if text then
            -- Check each stat pattern
            for pattern, statName in pairs(STAT_PATTERNS) do
                local value = string.match(text, pattern)
                if value then
                    value = tonumber(value)
                    if statName == "allstats" then
                        -- Add to all primary stats
                        stats.strength = (stats.strength or 0) + value
                        stats.agility = (stats.agility or 0) + value
                        stats.stamina = (stats.stamina or 0) + value
                        stats.intellect = (stats.intellect or 0) + value
                        stats.spirit = (stats.spirit or 0) + value
                    else
                        stats[statName] = (stats[statName] or 0) + value
                    end
                end
            end
        end
    end
    
    scanTip:Hide()
    return stats
end

-- Function to calculate stat score based on priorities
local function calculateStatScore(stats)
    local score = 0
    for stat, value in pairs(stats) do
        local priority = addon.config.statPriority[stat]
        if priority and priority > 0 then
            score = score + (value * priority)
        end
    end
    return score
end

-- Function to compare items by stats
local function compareItemsByStats(newItemLink, equippedItemLink)
    if not equippedItemLink then
        return true, 0  -- No item equipped, new item is upgrade
    end
    
    local newStats = getItemStats(newItemLink)
    local equippedStats = getItemStats(equippedItemLink)
    
    local newScore = calculateStatScore(newStats)
    local equippedScore = calculateStatScore(equippedStats)
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r New item score: %.1f, Equipped score: %.1f", newScore, equippedScore))
    end
    
    return newScore > equippedScore, newScore - equippedScore
end

-- Function to check if a recipe is for player's professions
local function isRecipeForMyProfession(itemLink)
    -- Ensure config and tables exist
    if not addon.config then return false end
    addon.config.myProfessions = addon.config.myProfessions or {}
    
    if not addon.config.recipeAlert or #addon.config.myProfessions == 0 then
        return false
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    
    -- Ensure RECIPE_PROFESSIONS exists
    if not RECIPE_PROFESSIONS then return false end
    
    -- Check each recipe type
    for prefix, professions in pairs(RECIPE_PROFESSIONS) do
        if string.find(itemName, prefix) then
            -- Handle both single profession and multiple profession cases
            if type(professions) == "string" then
                for _, myProf in ipairs(addon.config.myProfessions) do
                    if string.lower(professions) == string.lower(myProf) then
                        return true, professions
                    end
                end
            elseif type(professions) == "table" then
                for _, prof in ipairs(professions) do
                    for _, myProf in ipairs(addon.config.myProfessions) do
                        if string.lower(prof) == string.lower(myProf) then
                            return true, prof
                        end
                    end
                end
            end
        end
    end
    
    -- Special check for cooking recipes (they don't always have a prefix)
    if string.find(itemName, "Recipe") and not string.find(itemName, "Recipe: ") then
        for _, myProf in ipairs(addon.config.myProfessions) do
            if string.lower(myProf) == "cooking" then
                return true, "Cooking"
            end
        end
    end
    
    return false
end

-- Chat message handler
local function onChatMessage(self, event, message, sender, ...)
    -- Only process guild messages for items now
    if event == "CHAT_MSG_GUILD" then
        -- Check for item links in guild chat
        for _, itemLink in ipairs(extractItemLinks(message)) do
            -- Check for recipes first
            local isRecipe, profession = isRecipeForMyProfession(itemLink)
            if isRecipe then
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffffcc00%s recipe detected!|r %s", profession, itemLink))
                print(string.format("|cff00ff00[GuildItemScanner]|r From: %s", sender))
                
                if addon.config.soundAlert then
                    PlaySound(3332)
                end
            else
                -- Check for equipment upgrades
                processItemLink(itemLink, sender)
            end
        end
    end
end

-- Slash commands
local function onSlashCommand(msg)
    local cmd, args = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    args = args or ""
    
    if cmd == "test" then
        local playerName = UnitName("player")
        processItemLink("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", playerName, true)
    elseif cmd == "testgz" then
        -- Test the achievement detection
        checkForAchievement("[Frontier] TestPlayer earned achievement: Test Achievement")
        print("|cff00ff00[GuildItemScanner]|r Tested achievement detection")
    elseif cmd == "debug" then
        addon.config.debugMode = not addon.config.debugMode
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (addon.config.debugMode and "enabled" or "disabled"))
    elseif cmd == "whisper" then
        addon.config.whisperMode = not addon.config.whisperMode
        print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (addon.config.whisperMode and "enabled" or "disabled"))
    elseif cmd == "greed" then
        addon.config.greedMode = not addon.config.greedMode
        print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (addon.config.greedMode and "enabled" or "disabled"))
        -- Note: greed mode now only affects whether the button appears
    elseif cmd == "gz" then
        addon.config.autoGZ = not addon.config.autoGZ
        print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (addon.config.autoGZ and "enabled" or "disabled"))
        GuildItemScannerDB.config = addon.config  -- Save the setting
    elseif cmd == "rip" then
        addon.config.autoRIP = not addon.config.autoRIP
        print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (addon.config.autoRIP and "enabled" or "disabled"))
        GuildItemScannerDB.config = addon.config  -- Save the setting
    elseif cmd == "prof" then
        if args == "" then
            -- Show current professions
            if #addon.config.myProfessions == 0 then
                print("|cff00ff00[GuildItemScanner]|r No professions set. Use /gis prof add <profession> or /gis prof clear")
            else
                print("|cff00ff00[GuildItemScanner]|r Your professions: " .. table.concat(addon.config.myProfessions, ", "))
            end
            print("|cff00ff00[GuildItemScanner]|r Valid professions: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Leatherworking, Tailoring")
        else
            local subCmd, profession = args:match("^(%S+)%s*(.*)$")
            subCmd = subCmd and subCmd:lower() or ""
            profession = profession or ""
            
            if addon.config.debugMode then
                print(string.format("|cff00ff00[GIS Debug]|r args='%s', subCmd='%s', profession='%s'", args, subCmd, profession))
            end
            
            if subCmd == "add" and profession ~= "" then
                -- Capitalize first letter
                profession = profession:gsub("^%l", string.upper)
                -- Check for duplicates
                local alreadyExists = false
                for _, prof in ipairs(addon.config.myProfessions) do
                    if string.lower(prof) == string.lower(profession) then
                        alreadyExists = true
                        break
                    end
                end
                
                if not alreadyExists then
                    table.insert(addon.config.myProfessions, profession)
                    print("|cff00ff00[GuildItemScanner]|r Added profession: " .. profession)
                    GuildItemScannerDB.config = addon.config
                else
                    print("|cff00ff00[GuildItemScanner]|r You already have " .. profession)
                end
            elseif subCmd == "remove" and profession ~= "" then
                profession = profession:gsub("^%l", string.upper)
                local removed = false
                for i, prof in ipairs(addon.config.myProfessions) do
                    if string.lower(prof) == string.lower(profession) then
                        table.remove(addon.config.myProfessions, i)
                        print("|cff00ff00[GuildItemScanner]|r Removed profession: " .. profession)
                        GuildItemScannerDB.config = addon.config
                        removed = true
                        break
                    end
                end
                if not removed then
                    print("|cff00ff00[GuildItemScanner]|r You don't have " .. profession)
                end
            elseif subCmd == "clear" then
                addon.config.myProfessions = {}
                print("|cff00ff00[GuildItemScanner]|r Cleared all professions")
                GuildItemScannerDB.config = addon.config
            else
                print("|cff00ff00[GuildItemScanner]|r Usage: /gis prof [add|remove|clear] <profession>")
            end
        end
    elseif cmd == "recipe" then
        addon.config.recipeAlert = not addon.config.recipeAlert
        print("|cff00ff00[GuildItemScanner]|r Recipe alerts " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        GuildItemScannerDB.config = addon.config
    elseif cmd == "stat" or cmd == "stats" then
        if args == "" then
            -- Show current stat priorities
            if not next(addon.config.statPriority) then
                print("|cff00ff00[GuildItemScanner]|r No stat priorities set. Use /gis stat <stat> <weight>")
                print("|cff00ff00[GuildItemScanner]|r Example: /gis stat agility 2.5")
            else
                print("|cff00ff00[GuildItemScanner]|r Current stat priorities:")
                for stat, weight in pairs(addon.config.statPriority) do
                    print(string.format("  %s: %.1f", stat, weight))
                end
            end
            print("|cff00ff00[GuildItemScanner]|r Valid stats: strength, agility, stamina, intellect, spirit, attackpower, spellpower, healing, crit, hit, defense")
            print("|cff00ff00[GuildItemScanner]|r Use /gis stat clear to reset all priorities")
            print("|cff00ff00[GuildItemScanner]|r Use /gis stat mode to toggle between stat and ilvl evaluation")
        else
            local subCmd, rest = args:match("^(%S+)%s*(.*)$")
            subCmd = subCmd and subCmd:lower() or ""
            
            if subCmd == "clear" then
                addon.config.statPriority = {}
                print("|cff00ff00[GuildItemScanner]|r Cleared all stat priorities")
                GuildItemScannerDB.config = addon.config
            elseif subCmd == "mode" then
                addon.config.useStatPriority = not addon.config.useStatPriority
                if addon.config.useStatPriority and not next(addon.config.statPriority) then
                    print("|cff00ff00[GuildItemScanner]|r Stat priority mode enabled but no priorities set!")
                else
                    print("|cff00ff00[GuildItemScanner]|r Evaluation mode: " .. (addon.config.useStatPriority and "Stat Priority" or "Item Level"))
                end
                GuildItemScannerDB.config = addon.config
            else
                -- Setting a stat priority
                local weight = tonumber(rest)
                if weight then
                    addon.config.statPriority[subCmd] = weight
                    print(string.format("|cff00ff00[GuildItemScanner]|r Set %s priority to %.1f", subCmd, weight))
                    GuildItemScannerDB.config = addon.config
                elseif rest == "" then
                    -- Remove stat priority
                    addon.config.statPriority[subCmd] = nil
                    print(string.format("|cff00ff00[GuildItemScanner]|r Removed %s priority", subCmd))
                    GuildItemScannerDB.config = addon.config
                else
                    print("|cff00ff00[GuildItemScanner]|r Usage: /gis stat <stat> <weight>")
                    print("|cff00ff00[GuildItemScanner]|r Example: /gis stat agility 2.5")
                end
            end
        end
    elseif cmd == "status" then
        local _, class = UnitClass("player")
        print("|cff00ff00[GuildItemScanner]|r Status:")
        print("  Player class: " .. class)
        print("  Debug mode: " .. (addon.config.debugMode and "enabled" or "disabled"))
        print("  Whisper mode: " .. (addon.config.whisperMode and "enabled" or "disabled"))
        print("  Greed mode: " .. (addon.config.greedMode and "enabled" or "disabled"))
        print("  Auto-GZ mode: " .. (addon.config.autoGZ and "enabled" or "disabled"))
        print("  Auto-RIP mode: " .. (addon.config.autoRIP and "enabled" or "disabled"))
        print("  Recipe alerts: " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        print("  Professions: " .. (#addon.config.myProfessions > 0 and table.concat(addon.config.myProfessions, ", ") or "None"))
        print("  Evaluation mode: " .. (addon.config.useStatPriority and "Stat Priority" or "Item Level"))
        
        -- Show stat priorities sorted by weight
        if next(addon.config.statPriority) then
            local statList = {}
            for stat, weight in pairs(addon.config.statPriority) do
                table.insert(statList, {stat = stat, weight = weight})
            end
            -- Sort by weight (highest first)
            table.sort(statList, function(a, b) return a.weight > b.weight end)
            
            print("  Stat priorities (highest to lowest):")
            for _, entry in ipairs(statList) do
                print(string.format("    %s: %.1f", entry.stat, entry.weight))
            end
        end
    else
        print("|cff00ff00[GuildItemScanner]|r Commands:")
        print(" /gis test - Test an equipment alert")
        print(" /gis debug - Toggle debug logging")
        print(" /gis whisper - Toggle whisper mode")
        print(" /gis greed - Toggle loot message mode")
        print(" /gis gz - Toggle auto-congratulations for achievements")
        print(" /gis rip - Toggle auto-RIPBOZO for deaths")
        print(" /gis prof - Manage your professions")
        print(" /gis recipe - Toggle recipe alerts")
        print(" /gis stat - Manage stat priorities for gear evaluation")
        print(" /gis status - Show current configuration")
    end
end

-- Hook into chat frame to catch Frontier messages
local function HookChatFrame()
    local originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
    DEFAULT_CHAT_FRAME.AddMessage = function(self, text, ...)
        -- Check if this is a Frontier achievement message (but NOT our debug message)
        if text and string.find(text, "%[Frontier%]") and not string.find(text, "%[GIS Debug%]") then
            -- Strip color codes
            local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            cleanText = string.gsub(cleanText, "|r", "")
            
            -- Check for achievement messages
            if string.find(text, "earned achievement:") then
                -- Extract player name from achievement message
                local playerName = string.match(cleanText, "%[Frontier%]%s*(.-)%s*earned achievement:")
                
                if addon.config.debugMode then
                    originalAddMessage(self, "|cff00ff00[GIS Debug]|r Caught achievement: " .. text)
                    originalAddMessage(self, "|cff00ff00[GIS Debug]|r Clean text: " .. cleanText)
                    if playerName then
                        originalAddMessage(self, "|cff00ff00[GIS Debug]|r Player name: " .. playerName)
                        originalAddMessage(self, "|cff00ff00[GIS Debug]|r Auto-GZ enabled: " .. tostring(addon.config.autoGZ))
                    else
                        originalAddMessage(self, "|cff00ff00[GIS Debug]|r Failed to extract player name")
                    end
                end
                
                if playerName and addon.config.autoGZ then
                    -- Wait 1 second before sending GZ to avoid appearing automated
                    C_Timer.After(1, function()
                        SendChatMessage("GZ", "GUILD")
                        originalAddMessage(DEFAULT_CHAT_FRAME, string.format("|cff00ff00[GIS]|r Auto-congratulated %s for their achievement!", playerName))
                    end)
                end
            
            -- Check for death messages
            elseif string.find(text, "has died") then
                -- Extract player name from death message
                local playerName = string.match(cleanText, "%[Frontier%]%s*(.-)%s*has died")
                
                if addon.config.debugMode then
                    originalAddMessage(self, "|cff00ff00[GIS Debug]|r Caught death: " .. text)
                    originalAddMessage(self, "|cff00ff00[GIS Debug]|r Clean text: " .. cleanText)
                    if playerName then
                        originalAddMessage(self, "|cff00ff00[GIS Debug]|r Player name: " .. playerName)
                        originalAddMessage(self, "|cff00ff00[GIS Debug]|r Auto-RIP enabled: " .. tostring(addon.config.autoRIP))
                    else
                        originalAddMessage(self, "|cff00ff00[GIS Debug]|r Failed to extract player name")
                    end
                end
                
                if playerName and addon.config.autoRIP then
                    -- Wait 1 second before sending RIPBOZO to avoid appearing automated
                    C_Timer.After(1, function()
                        SendChatMessage("RIPBOZO", "GUILD")
                        originalAddMessage(DEFAULT_CHAT_FRAME, string.format("|cff00ff00[GIS]|r Auto-RIP for %s!", playerName))
                    end)
                end
            end
        end
        
        -- Call the original function for all other messages
        return originalAddMessage(self, text, ...)
    end
end

-- Initialization
local function onPlayerLogin()
    LoadSavedVariables()
    HookChatFrame()  -- Hook the chat frame when player logs in
    local _, class = UnitClass("player")
    print("|cff00ff00[GuildItemScanner]|r Loaded for " .. class .. ". Type /gis for commands.")
end

-- Event registration
local GIS = CreateFrame("Frame")
GIS:RegisterEvent("CHAT_MSG_GUILD")
GIS:RegisterEvent("PLAYER_LOGIN")
GIS:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        onPlayerLogin()
    else
        onChatMessage(self, event, ...)
    end
end)

SLASH_GUILDITEMSCANNER1 = "/gis"
SlashCmdList["GUILDITEMSCANNER"] = onSlashCommand
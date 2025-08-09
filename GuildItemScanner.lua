-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Monitors guild chat for BoE equipment upgrades and profession recipes, with visual and sound alerts

local GZ_MESSAGES = {
    "GZ",
    "gz",
    "grats!",
    "LETSGOOO",
    "gratz",
	"DinkDonk",
	"grats"
}

local addonName, addon = ...
addon.config = {
    enabled = true,  -- Global on/off switch
    soundAlert = true,
    whisperMode = false,
    greedMode = true,
    recipeButton = true,  -- Enable recipe request button by default
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
alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
alertFrame:SetBackdropColor(0, 0, 0, 0.9)
alertFrame:EnableMouse(true)
alertFrame:SetMovable(true)
alertFrame:SetFrameStrata("DIALOG")
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", alertFrame.StartMoving)
alertFrame:SetScript("OnDragStop", alertFrame.StopMovingOrSizing)
alertFrame:Hide()

-- Alert text
local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertText:SetPoint("TOP", alertFrame, "TOP", 0, -25)
alertText:SetWidth(580)
alertText:SetJustifyH("CENTER")

-- Greed button
local greedButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
greedButton:SetSize(100, 25)
greedButton:SetPoint("BOTTOMLEFT", alertFrame, "BOTTOM", -60, 15)
greedButton:SetText("Greed!")

-- Recipe request button
local recipeButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
recipeButton:SetSize(100, 25)
recipeButton:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOM", 60, 15)
recipeButton:SetText("Request Recipe")

-- Close button
local closeButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() alertFrame:Hide() end)

-- Alert management
local currentAlert = nil

local SLOT_MAPPING = {
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_HEAD = "head",
    INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_BODY = "shirt",
    INVTYPE_CHEST = "chest", INVTYPE_ROBE = "chest", INVTYPE_WAIST = "waist", 
    INVTYPE_LEGS = "legs", INVTYPE_FEET = "feet", INVTYPE_WRIST = "wrist", 
    INVTYPE_HAND = "hands", INVTYPE_CLOAK = "back", INVTYPE_WEAPON = "main hand", 
    INVTYPE_SHIELD = "off hand", INVTYPE_2HWEAPON = "two-hand", 
    INVTYPE_WEAPONMAINHAND = "main hand", INVTYPE_WEAPONOFFHAND = "off hand", 
    INVTYPE_HOLDABLE = "off hand", INVTYPE_RANGED = "ranged", INVTYPE_THROWN = "ranged",
    INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_RELIC = "ranged", INVTYPE_TABARD = "tabard"
}

local SLOT_ID_MAPPING = {
    INVTYPE_FINGER = 11, INVTYPE_TRINKET = 13, INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5, INVTYPE_ROBE = 5, INVTYPE_WAIST = 6, 
    INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, 
    INVTYPE_HAND = 10, INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16, 
    INVTYPE_SHIELD = 17, INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, 
    INVTYPE_WEAPONOFFHAND = 17, INVTYPE_HOLDABLE = 17, INVTYPE_RANGED = 18, 
    INVTYPE_THROWN = 18, INVTYPE_RANGEDRIGHT = 18, INVTYPE_RELIC = 18, INVTYPE_TABARD = 19
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

-- Recipe profession mappings
local RECIPE_PROFESSIONS = {
    ["Recipe: "] = {"Alchemy", "Cooking"},
    ["Formula: "] = "Enchanting",
    ["Pattern: "] = {"Tailoring", "Leatherworking"},
    ["Plans: "] = "Blacksmithing",
    ["Schematic: "] = "Engineering"
}

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
    ["(%d+) Defense"] = "defense",  -- Classic version
    ["Defense %+(%d+)"] = "defense",  -- Another Classic format
    ["(%d+) Dodge Rating"] = "dodge",
    ["(%d+) Dodge"] = "dodge",  -- Classic version
    ["(%d+) Parry Rating"] = "parry",
    ["(%d+) Parry"] = "parry",  -- Classic version
    ["(%d+) Block Rating"] = "block",
    ["(%d+) Block"] = "block",  -- Classic version
    -- Resistances
    ["(%d+) Fire Resistance"] = "fireres",
    ["(%d+) Nature Resistance"] = "natureres",
    ["(%d+) Frost Resistance"] = "frostres",
    ["(%d+) Shadow Resistance"] = "shadowres",
    ["(%d+) Arcane Resistance"] = "arcaneres",
    -- All stats
    ["%+(%d+) All Stats"] = "allstats",
    ["%+(%d+) to All Stats"] = "allstats",
    -- Additional stats
    ["(%d+) Mana per 5 sec"] = "mp5",
    ["(%d+) to all Resistances"] = "allres",
    ["Mana Regen (%d+) per 5 sec%."] = "mp5",  -- Alternative format
    -- Weapon stats
    ["%+(%d+) Weapon Damage"] = "weapondamage",
    -- Armor
    ["(%d+) Armor"] = "armor",
    ["%+(%d+) Armor"] = "armor"
}

local function LoadSavedVariables()
    GuildItemScannerDB = GuildItemScannerDB or {
        config = {
            enabled = true,
            soundAlert = true,
            whisperMode = false,
            greedMode = true,
            recipeButton = true,
            alertDuration = 10,
            debugMode = false,
            autoGZ = false,
            autoRIP = false,
            recipeAlert = true,
            myProfessions = {},
            statPriority = {},
            useStatPriority = false
        },
        alertHistory = {},
        uncachedHistory = {}
    }
    
    -- Ensure all config fields exist
    addon.config = GuildItemScannerDB.config
    addon.config.enabled = addon.config.enabled ~= false  -- Default to true if not set
    addon.config.myProfessions = addon.config.myProfessions or {}
    addon.config.autoGZ = addon.config.autoGZ or false
    addon.config.autoRIP = addon.config.autoRIP or false
    addon.config.recipeAlert = addon.config.recipeAlert ~= false
    addon.config.recipeButton = addon.config.recipeButton ~= false
    addon.config.statPriority = addon.config.statPriority or {}
    addon.config.useStatPriority = addon.config.useStatPriority or false
    
    addon.alertHistory = GuildItemScannerDB.alertHistory
    addon.uncachedHistory = GuildItemScannerDB.uncachedHistory
end

-- Reusable tooltip for scanning
local scanTip = CreateFrame("GameTooltip", "GIScanTooltip", nil, "GameTooltipTemplate")

-- Function to get item stats
local function getItemStats(itemLink)
    local stats = {}
    
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetHyperlink(itemLink)
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Scanning stats for: %s", itemLink))
        print(string.format("|cff00ff00[GIS Debug]|r Tooltip lines: %d", scanTip:NumLines()))
    end
    
    for i = 1, scanTip:NumLines() do
        local text = _G["GIScanTooltipTextLeft" .. i]:GetText()
        if text then
            if addon.config.debugMode and i <= 10 then -- Only show first 10 lines in debug
                print(string.format("|cff00ff00[GIS Debug]|r Line %d: %s", i, text))
            end
            for pattern, statName in pairs(STAT_PATTERNS) do
                local value = string.match(text, pattern)
                if value then
                    value = tonumber(value)
                    if statName == "allstats" then
                        stats.strength = (stats.strength or 0) + value
                        stats.agility = (stats.agility or 0) + value
                        stats.stamina = (stats.stamina or 0) + value
                        stats.intellect = (stats.intellect or 0) + value
                        stats.spirit = (stats.spirit or 0) + value
                    else
                        stats[statName] = (stats[statName] or 0) + value
                    end
                    if addon.config.debugMode then
                        print(string.format("|cff00ff00[GIS Debug]|r Found stat: %s = %d", statName, value))
                    end
                end
            end
            
            -- Check for "Equip:" bonuses (Classic format)
            if string.find(text, "Equip:") then
                -- Equip: Defense +X
                local defense = string.match(text, "Equip: Defense %+(%d+)")
                if defense then
                    stats.defense = (stats.defense or 0) + tonumber(defense)
                    if addon.config.debugMode then
                        print(string.format("|cff00ff00[GIS Debug]|r Found equip bonus: defense = %d", tonumber(defense)))
                    end
                end
                -- Add more Equip: patterns as needed
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
        return true, 0
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

-- Function to check if player meets item level requirements
local function canPlayerUseItemLevel(itemLink)
    local playerLevel = UnitLevel("player")
    local _, _, _, _, requiredLevel = GetItemInfo(itemLink)
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Player level: %d, Item required level: %s", 
            playerLevel, tostring(requiredLevel)))
    end
    
    -- If we can't get the required level, assume it's usable (fallback)
    if not requiredLevel then
        if addon.config.debugMode then
            print("|cff00ff00[GIS Debug]|r Could not determine required level, allowing item")
        end
        return true
    end
    
    local canUse = playerLevel >= requiredLevel
    if addon.config.debugMode and not canUse then
        print(string.format("|cff00ff00[GIS Debug]|r Cannot use: Level %d required (player is %d)", 
            requiredLevel, playerLevel))
    end
    
    return canUse
end

local function canPlayerUseItem(itemLink)
    -- First check level requirements
    if not canPlayerUseItemLevel(itemLink) then
        return false
    end
    
    local _, class = UnitClass("player")
    local _, _, _, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    
    if addon.config.debugMode then
        local slotName = SLOT_MAPPING[itemEquipLoc] or itemEquipLoc or "unknown"
        print(string.format("|cff00ff00[GIS Debug]|r %s %s (%s)", 
            itemSubType or "Unknown", slotName, class))
    end
    
    local isArmor = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_SHOULDER" or
        itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or
        itemEquipLoc == "INVTYPE_WAIST" or itemEquipLoc == "INVTYPE_LEGS" or 
        itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_WRIST" or 
        itemEquipLoc == "INVTYPE_HAND" or itemEquipLoc == "INVTYPE_CLOAK" or 
        itemEquipLoc == "INVTYPE_BODY"
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
    
    return true
end

local function isItemUpgrade(itemLink)
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Checking upgrade: %s", itemLink))
    end
    
    if not canPlayerUseItem(itemLink) then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Rejected: |cffff0000Wrong class or level|r"))
        end
        return false
    end

    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not (itemLevel and itemEquipLoc) then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Missing item info for %s", itemLink))
        end
        return false
    end

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

    if addon.config.useStatPriority and next(addon.config.statPriority) then
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
            print(string.format("|cff00ff00[GIS Debug]|r Not a stat upgrade for %s", itemLink))
        end
        return false
    else
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
                print(string.format("|cff00ff00[GIS Debug]|r ilvl %d vs %d for %s", itemLevel, lowestEquippedLevel, itemLink))
            end
        end
        return itemLevel > lowestEquippedLevel, itemLevel - lowestEquippedLevel
    end
end

local function addToHistory(itemLink, playerName, itemType)
    table.insert(addon.alertHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        type = itemType or "Equipment",
        status = "POSTED"
    })
    while #addon.alertHistory > MAX_HISTORY do
        table.remove(addon.alertHistory)
    end
end

-- Greed button click handler
greedButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "I'll take " .. currentAlert.itemLink .. " if no one needs"
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

-- Recipe request button click handler
recipeButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "Can I have that " .. currentAlert.itemLink .. "? Thanks!"
        if addon.config.whisperMode then
            SendChatMessage(msg, "WHISPER", nil, currentAlert.playerName)
            print("|cff00ff00[GuildItemScanner]|r Whispered recipe request to " .. currentAlert.playerName)
        else
            SendChatMessage(msg, "GUILD")
            print("|cff00ff00[GuildItemScanner]|r Sent recipe request to guild")
        end
        alertFrame:Hide()
    end
end)

local function playAlertSound()
    if addon.config.soundAlert then
        local soundEnabled = GetCVar("Sound_EnableSFX") == "1"
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Sound settings: soundAlert=%s, Sound_EnableSFX=%s", 
                tostring(addon.config.soundAlert), GetCVar("Sound_EnableSFX")))
        end
        
        local success = PlaySoundFile("Interface\\AddOns\\GuildItemScanner\\Sounds\\Alert.ogg")
        if not success then
            -- Primary fallback
            success = PlaySound(SOUNDKIT.UI_BONUS_LOOT_ROLL_END)
            if not success then
                -- Secondary fallback
                PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
                if addon.config.debugMode then
                    print("|cff00ff00[GIS Debug]|r Custom sound and UI_BONUS_LOOT_ROLL_END failed, using IG_MAINMENU_OPEN")
                end
            elseif addon.config.debugMode then
                print("|cff00ff00[GIS Debug]|r Custom sound failed, using UI_BONUS_LOOT_ROLL_END")
            end
        elseif addon.config.debugMode then
            print("|cff00ff00[GIS Debug]|r Played custom sound")
        end
    elseif addon.config.debugMode then
        print("|cff00ff00[GIS Debug]|r Sound alert disabled")
    end
end

local function showAlert(itemLink, playerName)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
    
    addToHistory(itemLink, playerName, "Equipment")

    local upgradeText, detailText
    if addon.config.useStatPriority and next(addon.config.statPriority) then
        local isUpgrade, scoreDiff = isItemUpgrade(itemLink)
        upgradeText = string.format("+%.1f stat score upgrade: %s", scoreDiff, itemLink)
        
        local stats = getItemStats(itemLink)
        local statList = {}
        for stat, value in pairs(stats) do
            if addon.config.statPriority[stat] and addon.config.statPriority[stat] > 0 then
                table.insert(statList, string.format("%s: %d (x%.1f)", stat, value, addon.config.statPriority[stat]))
            end
        end
        detailText = string.format("From: %s (%s)", playerName, #statList > 0 and table.concat(statList, ", ") or "no priority stats")
    else
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

    print(string.format("|cff00ff00[GuildItemScanner]|r %s", upgradeText))
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", detailText))

    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        itemLevel = itemLevel,
        slot = slot
    }
    
    alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00%s|r", 
        playerName, itemLink, detailText))
    
    if addon.config.greedMode then
        greedButton:Show()
    else
        greedButton:Hide()
    end
    recipeButton:Hide()
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Showing equipment alert for %s at %s, isVisible=%s", 
            itemLink, alertFrame:GetPoint(1), tostring(alertFrame:IsVisible())))
    end
    
    alertFrame:Show()
    alertFrame:SetFrameLevel(10)
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
            if addon.config.debugMode then
                print("|cff00ff00[GIS Debug]|r Equipment alert hidden after duration")
            end
        end
    end)
end

local function showRecipeAlert(itemLink, playerName, profession)
    addToHistory(itemLink, playerName, "Recipe")

    local alertMsg = string.format("%s recipe detected: %s", profession, itemLink)
    local detailText = string.format("From: %s", playerName)

    print(string.format("|cff00ff00[GuildItemScanner]|r |cffffcc00%s|r", alertMsg))
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", detailText))

    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        slot = "recipe",
        profession = profession
    }
    
    alertText:SetText(string.format("%s recipe from %s:\n%s\n|cff00ff00%s|r", 
        profession, playerName, itemLink, detailText))
    
    greedButton:Hide()
    if addon.config.recipeButton then
        recipeButton:Show()
    else
        recipeButton:Hide()
    end
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Showing recipe alert for %s (%s) at %s, isVisible=%s", 
            itemLink, profession, alertFrame:GetPoint(1), tostring(alertFrame:IsVisible())))
    end
    
    alertFrame:Show()
    alertFrame:SetFrameLevel(10)
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
            if addon.config.debugMode then
                print("|cff00ff00[GIS Debug]|r Recipe alert hidden after duration")
            end
        end
    end)
end

local function extractItemLinks(message)
    local items = {}
    for itemLink in string.gmatch(message, "|c%x+|Hitem:.-|h%[.-%]|h|r") do
        table.insert(items, itemLink)
    end
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Extracted %d item links from message: %s", #items, message))
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
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Max retries reached for %s", retryEntry.itemLink))
        end
        return
    end
    retryEntry.retryCount = retryEntry.retryCount + 1
    processItemLink(retryEntry.itemLink, retryEntry.playerName, true)
end

function processItemLink(itemLink, playerName, skipCooldown)
    if not itemLink or not playerName then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Invalid itemLink or playerName: %s, %s", tostring(itemLink), tostring(playerName)))
        end
        return
    end

    local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName then
        table.insert(retryQueue, { itemLink = itemLink, playerName = playerName, retryCount = 0 })
        addToUncachedHistory(itemLink, playerName, "Waiting for item info cache...")
        C_Timer.After(RETRY_DELAY, retryUncachedItems)
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Item info not cached for %s, retrying", itemLink))
        end
        return
    end

    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Processing item: %s, bindType=%s, equipLoc=%s", 
            itemLink, tostring(bindType), itemEquipLoc or "nil"))
    end

    if itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Skipped non-equippable item: %s", itemLink))
        end
        return
    end

    if bindType == 1 then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Rejected: |cffff0000BoP|r %s", itemLink))
        end
        return
    end

    if isItemUpgrade(itemLink) then
        showAlert(itemLink, playerName)
    elseif addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Rejected: |cffff0000Not upgrade|r %s", itemLink))
    end
end

-- Function to check if a recipe is for player's professions
local function isRecipeForMyProfession(itemLink)
    if not addon.config or not addon.config.recipeAlert or #addon.config.myProfessions == 0 then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Recipe check skipped: Alerts %s, Professions %d",
                tostring(addon.config.recipeAlert), #addon.config.myProfessions))
        end
        return false
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then
        if addon.config.debugMode then
            print("|cff00ff00[GIS Debug]|r No item name found in link")
        end
        return false
    end
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Checking recipe: %s", itemName))
    end
    
    for prefix, professions in pairs(RECIPE_PROFESSIONS) do
        if string.find(itemName, prefix, 1, true) then
            if type(professions) == "string" then
                for _, myProf in ipairs(addon.config.myProfessions) do
                    if string.lower(professions) == string.lower(myProf) then
                        if addon.config.debugMode then
                            print(string.format("|cff00ff00[GIS Debug]|r Matched %s recipe for %s", professions, myProf))
                        end
                        return true, professions
                    end
                end
            elseif type(professions) == "table" then
                -- Prioritize Cooking for "Recipe: " if player has Cooking
                for _, myProf in ipairs(addon.config.myProfessions) do
                    if string.lower(myProf) == "cooking" and prefix == "Recipe: " then
                        if addon.config.debugMode then
                            print(string.format("|cff00ff00[GIS Debug]|r Matched Cooking recipe for %s", myProf))
                        end
                        return true, "Cooking"
                    end
                end
                -- Check other professions
                for _, prof in ipairs(professions) do
                    for _, myProf in ipairs(addon.config.myProfessions) do
                        if string.lower(prof) == string.lower(myProf) then
                            if addon.config.debugMode then
                                print(string.format("|cff00ff00[GIS Debug]|r Matched %s recipe for %s", prof, myProf))
                            end
                            return true, prof
                        end
                    end
                end
            end
        end
    end
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r No profession match for: %s", itemName))
    end
    return false
end

-- Chat message handler
local function onChatMessage(self, event, message, sender, ...)
    -- Check if addon is globally disabled
    if not addon.config.enabled then
        if addon.config.debugMode then
            print("|cff00ff00[GIS Debug]|r Addon is disabled, ignoring message")
        end
        return
    end
    
    if event == "CHAT_MSG_GUILD" then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GIS Debug]|r Processing guild chat from %s: %s", sender, message))
        end
        local itemLinks = extractItemLinks(message)
        if #itemLinks == 0 and addon.config.debugMode then
            print("|cff00ff00[GIS Debug]|r No item links found in message")
        end
        for _, itemLink in ipairs(itemLinks) do
            local isRecipe, profession = isRecipeForMyProfession(itemLink)
            if isRecipe then
                showRecipeAlert(itemLink, sender, profession)
            else
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
    
    if cmd == "on" then
        addon.config.enabled = true
        print("|cff00ff00[GuildItemScanner]|r Addon |cff00ff00ENABLED|r - Scanning guild chat for upgrades")
        GuildItemScannerDB.config = addon.config
    elseif cmd == "off" then
        addon.config.enabled = false
        print("|cff00ff00[GuildItemScanner]|r Addon |cffff0000DISABLED|r - Not scanning guild chat")
        GuildItemScannerDB.config = addon.config
    elseif cmd == "test" then
        local playerName = UnitName("player")
        processItemLink("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", playerName, true)
    elseif cmd == "testrecipe" then
        local playerName = UnitName("player")
        local isRecipe, profession = isRecipeForMyProfession("|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r")
        if isRecipe then
            showRecipeAlert("|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r", playerName, profession)
        else
            print("|cff00ff00[GuildItemScanner]|r No recipe match for test item")
        end
    elseif cmd == "debug" then
        addon.config.debugMode = not addon.config.debugMode
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (addon.config.debugMode and "enabled" or "disabled"))
    elseif cmd == "whisper" then
        addon.config.whisperMode = not addon.config.whisperMode
        print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (addon.config.whisperMode and "enabled" or "disabled"))
    elseif cmd == "greed" then
        addon.config.greedMode = not addon.config.greedMode
        print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (addon.config.greedMode and "enabled" or "disabled"))
    elseif cmd == "recipebutton" then
        addon.config.recipeButton = not addon.config.recipeButton
        print("|cff00ff00[GuildItemScanner]|r Recipe request button " .. (addon.config.recipeButton and "enabled" or "disabled"))
        GuildItemScannerDB.config = addon.config
    elseif cmd == "gz" then
        addon.config.autoGZ = not addon.config.autoGZ
        print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (addon.config.autoGZ and "enabled" or "disabled"))
        GuildItemScannerDB.config = addon.config
    elseif cmd == "rip" then
        addon.config.autoRIP = not addon.config.autoRIP
        print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (addon.config.autoRIP and "enabled" or "disabled"))
        GuildItemScannerDB.config = addon.config
    elseif cmd == "prof" then
        if args == "" then
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
                profession = profession:gsub("^%l", string.upper)
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
            if not next(addon.config.statPriority) then
                print("|cff00ff00[GuildItemScanner]|r No stat priorities set. Use /gis stat <stat> <weight>")
                print("|cff00ff00[GuildItemScanner]|r Example: /gis stat agility 2.5")
            else
                print("|cff00ff00[GuildItemScanner]|r Current stat priorities:")
                for stat, weight in pairs(addon.config.statPriority) do
                    print(string.format("  %s: %.1f", stat, weight))
                end
            end
            print("|cff00ff00[GuildItemScanner]|r Valid stats: strength, agility, stamina, intellect, spirit, attackpower, spellpower, healing, spelldamage, crit, hit, defense, dodge, parry, block, mp5, allres, armor, weapondamage")
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
                local weight = tonumber(rest)
                if weight then
                    addon.config.statPriority[subCmd] = weight
                    print(string.format("|cff00ff00[GuildItemScanner]|r Set %s priority to %.1f", subCmd, weight))
                    GuildItemScannerDB.config = addon.config
                elseif rest == "" then
                    addon.config.statPriority[subCmd] = nil
                    print(string.format("|cff00ff00[GIS Debug]|r Removed %s priority", subCmd))
                    GuildItemScannerDB.config = addon.config
                else
                    print("|cff00ff00[GuildItemScanner]|r Usage: /gis stat <stat> <weight>")
                    print("|cff00ff00[GuildItemScanner]|r Example: /gis stat agility 2.5")
                end
            end
        end
    elseif cmd == "compare" then
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
        if not canPlayerUseItem(itemLink) then
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
        
        -- Get slot info
        local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
        local slotsToCheck = {}
        
        if itemEquipLoc == "INVTYPE_FINGER" then
            slotsToCheck = {11, 12}
        elseif itemEquipLoc == "INVTYPE_TRINKET" then
            slotsToCheck = {13, 14}
        else
            local slotId = SLOT_ID_MAPPING[itemEquipLoc]
            if slotId then
                slotsToCheck = {slotId}
            end
        end
        
        if #slotsToCheck == 0 then
            print("|cff00ff00[GuildItemScanner]|r Unable to determine equipment slot for this item.")
            return
        end
        
        print(string.format("|cff00ff00[GuildItemScanner]|r Equipment slot: %s", slot))
        
        -- Compare using stat priority or item level
        if addon.config.useStatPriority and next(addon.config.statPriority) then
            -- Stat-based comparison
            local stats = getItemStats(itemLink)
            local statScore = calculateStatScore(stats)
            
            -- Print item stats
            print("|cff00ff00[GuildItemScanner]|r Item stats:")
            local hasRelevantStats = false
            local hasAnyStats = false
            for stat, value in pairs(stats) do
                hasAnyStats = true
                local priority = addon.config.statPriority[stat]
                if priority and priority > 0 then
                    print(string.format("  %s: %d (x%.1f = %.1f score)", stat, value, priority, value * priority))
                    hasRelevantStats = true
                elseif value > 0 then
                    print(string.format("  %s: %d (no priority)", stat, value))
                end
            end
            
            if not hasAnyStats then
                print("  |cffff0000No stats found on this item!|r")
                print("  |cffff0000This may be due to the item not being cached. Try again.|r")
            elseif not hasRelevantStats then
                print("  No prioritized stats found on this item")
            end
            
            print(string.format("|cff00ff00[GuildItemScanner]|r Total stat score: %.1f", statScore))
            
            -- Compare with equipped items
            print("|cff00ff00[GuildItemScanner]|r Equipped comparison:")
            local bestUpgrade = nil
            local bestScoreDiff = -999999
            
            for i, slotId in ipairs(slotsToCheck) do
                local equippedLink = GetInventoryItemLink("player", slotId)
                if equippedLink then
                    local equippedStats = getItemStats(equippedLink)
                    local equippedScore = calculateStatScore(equippedStats)
                    local scoreDiff = statScore - equippedScore
                    
                    local slotName = ""
                    if #slotsToCheck > 1 then
                        slotName = string.format(" (slot %d)", i)
                    end
                    
                    if scoreDiff > 0 then
                        print(string.format("  %s%s: |cffa335ee+%.1f upgrade|r (%.1f vs %.1f)", 
                            equippedLink, slotName, scoreDiff, statScore, equippedScore))
                    else
                        print(string.format("  %s%s: |cffff0000%.1f downgrade|r (%.1f vs %.1f)", 
                            equippedLink, slotName, scoreDiff, statScore, equippedScore))
                    end
                    
                    if scoreDiff > bestScoreDiff then
                        bestScoreDiff = scoreDiff
                        bestUpgrade = equippedLink
                    end
                else
                    print(string.format("  Slot %d: |cff808080Empty|r - |cffa335eeDefinite upgrade!|r", i))
                    if bestScoreDiff < statScore then
                        bestScoreDiff = statScore
                        bestUpgrade = "empty slot"
                    end
                end
            end
            
            -- Summary
            if bestScoreDiff > 0 then
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%.1f stat score|r", bestScoreDiff))
            else
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffff0000Summary: Not an upgrade (%.1f stat score)|r", bestScoreDiff))
            end
            
        else
            -- Item level comparison
            print("|cff00ff00[GuildItemScanner]|r Equipped comparison (by item level):")
            local lowestEquippedLevel = 999
            local lowestEquippedLink = nil
            
            for i, slotId in ipairs(slotsToCheck) do
                local equippedLink = GetInventoryItemLink("player", slotId)
                local equippedLevel = getEquippedItemLevel(slotId)
                
                local slotName = ""
                if #slotsToCheck > 1 then
                    slotName = string.format(" (slot %d)", i)
                end
                
                if equippedLink then
                    if itemLevel > equippedLevel then
                        print(string.format("  %s%s: |cffa335ee+%d ilvl upgrade|r (ilvl %d)", 
                            equippedLink, slotName, itemLevel - equippedLevel, equippedLevel))
                    else
                        print(string.format("  %s%s: |cffff0000-%d ilvl downgrade|r (ilvl %d)", 
                            equippedLink, slotName, equippedLevel - itemLevel, equippedLevel))
                    end
                else
                    print(string.format("  Slot %d: |cff808080Empty|r - |cffa335eeDefinite upgrade!|r", i))
                    equippedLevel = 0
                end
                
                if equippedLevel < lowestEquippedLevel then
                    lowestEquippedLevel = equippedLevel
                    lowestEquippedLink = equippedLink or "empty slot"
                end
            end
            
            -- Summary
            if itemLevel > lowestEquippedLevel then
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%d item levels|r", 
                    itemLevel - lowestEquippedLevel))
            else
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffff0000Summary: Not an upgrade (%d item levels)|r", 
                    itemLevel - lowestEquippedLevel))
            end
        end
    elseif cmd == "status" then
        local _, class = UnitClass("player")
        local playerLevel = UnitLevel("player")
        print("|cff00ff00[GuildItemScanner]|r Status:")
        print("  Addon: " .. (addon.config.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
        print("  Player: " .. class .. " (Level " .. playerLevel .. ")")
        print("  Debug mode: " .. (addon.config.debugMode and "enabled" or "disabled"))
        print("  Whisper mode: " .. (addon.config.whisperMode and "enabled" or "disabled"))
        print("  Greed mode: " .. (addon.config.greedMode and "enabled" or "disabled"))
        print("  Recipe request button: " .. (addon.config.recipeButton and "enabled" or "disabled"))
        print("  Auto-GZ mode: " .. (addon.config.autoGZ and "enabled" or "disabled"))
        print("  Auto-RIP mode: " .. (addon.config.autoRIP and "enabled" or "disabled"))
        print("  Recipe alerts: " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        print("  Professions: " .. (#addon.config.myProfessions > 0 and table.concat(addon.config.myProfessions, ", ") or "None"))
        print("  Evaluation mode: " .. (addon.config.useStatPriority and "Stat Priority" or "Item Level"))
        
        if next(addon.config.statPriority) then
            local statList = {}
            for stat, weight in pairs(addon.config.statPriority) do
                table.insert(statList, {stat = stat, weight = weight})
            end
            table.sort(statList, function(a, b) return a.weight > b.weight end)
            
            print("  Stat priorities (highest to lowest):")
            for _, entry in ipairs(statList) do
                print(string.format("    %s: %.1f", entry.stat, entry.weight))
            end
        end
    else
        print("|cff00ff00[GuildItemScanner]|r Commands:")
        print(" /gis on - Enable scanning (turn addon ON)")
        print(" /gis off - Disable scanning (turn addon OFF)")
        print(" /gis test - Test an equipment alert")
        print(" /gis testrecipe - Test a recipe alert")
        print(" /gis debug - Toggle debug logging")
        print(" /gis whisper - Toggle whisper mode")
        print(" /gis greed - Toggle loot message mode")
        print(" /gis recipebutton - Toggle recipe request button")
        print(" /gis gz - Toggle auto-congratulations for achievements")
        print(" /gis rip - Toggle auto-RIP for deaths (level-based messages)")
        print(" /gis prof - Manage your professions")
        print(" /gis recipe - Toggle recipe alerts")
        print(" /gis stat - Manage stat priorities for gear evaluation")
        print(" /gis compare [item] - Compare any item with your equipped gear")
        print(" /gis status - Show current configuration")
    end
end

-- Hook into chat frame to catch Frontier messages
local function HookChatFrame()
    local originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
    DEFAULT_CHAT_FRAME.AddMessage = function(self, text, ...)
        -- Check if addon is globally disabled
        if not addon.config.enabled then
            return originalAddMessage(self, text, ...)
        end
        
        if text and string.find(text, "%[Frontier%]") and not string.find(text, "%[GIS Debug%]") then
            local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            cleanText = string.gsub(cleanText, "|r", "")
            
            if string.find(cleanText, "earned achievement:") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*earned achievement:")
                
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
					-- Don't congratulate yourself
					if playerName ~= UnitName("player") then
						-- 50% chance to congratulate
						local shouldCongratulate = math.random() <= 0.5
						if shouldCongratulate then
							-- Random delay between 2-6 seconds
							local delay = math.random(2, 6) + math.random() -- Add fractional seconds
							C_Timer.After(delay, function()
								-- Pick a random GZ message
								local gzMessage = GZ_MESSAGES[math.random(#GZ_MESSAGES)]
								SendChatMessage(gzMessage, "GUILD")
								originalAddMessage(DEFAULT_CHAT_FRAME, string.format("|cff00ff00[GIS]|r Auto-congratulated %s for their achievement! (%.1fs delay)", playerName, delay))
							end)
						elseif addon.config.debugMode then
							originalAddMessage(self, "|cff00ff00[GIS Debug]|r Skipped GZ (50% chance)")
						end
					elseif addon.config.debugMode then
						originalAddMessage(self, "|cff00ff00[GIS Debug]|r Skipped GZ for self (%s)", playerName)
					end
                end
            elseif string.find(cleanText, "has died") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*has died")
                
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
                
				if playerName and playerName ~= UnitName("player") and addon.config.autoRIP then
                    local level = string.match(text, "Level (%d+)") or string.match(cleanText, "Level (%d+)")
                    local deathMessage = "F"
                    if level then
                        level = tonumber(level)
                        if level < 30 then
                            -- Randomly choose between "RIP" and "F" for low levels
                            deathMessage = math.random() <= 0.5 and "RIP" or "F"
                        elseif level >= 30 and level <= 40 then
                            deathMessage = "F"
                        elseif level >= 41 and level <= 59 then
                            -- Randomly choose between "OMG F" and "F" for mid levels
                            deathMessage = math.random() <= 0.7 and "F" or "OMG F"
                        elseif level >= 60 then
                            -- Randomly choose between "F", "OMG F", and "GIGA F" for max level
                            local roll = math.random()
                            if roll <= 0.4 then
                                deathMessage = "F"
                            elseif roll <= 0.8 then
                                deathMessage = "OMG F"
                            else
                                deathMessage = "GIGA F"
                            end
                        end
                        
                        if addon.config.debugMode then
                            originalAddMessage(self, string.format("|cff00ff00[GIS Debug]|r Player level: %d, Message: %s", level, deathMessage))
                        end
                    else
                        -- No level info, just use simple message
                        deathMessage = math.random() <= 0.7 and "F" or "RIP"
                    end
                    
                    -- 60% chance to send RIP message
                    local shouldSendRIP = math.random() <= 0.6
                    if shouldSendRIP then
                        -- Random delay between 3-8 seconds
                        local delay = math.random(3, 8) + math.random() -- Add fractional seconds
                        C_Timer.After(delay, function()
                            SendChatMessage(deathMessage, "GUILD")
                            originalAddMessage(DEFAULT_CHAT_FRAME, string.format("|cff00ff00[GIS]|r Auto-RIP for %s: %s (%.1fs delay)", playerName, deathMessage, delay))
                        end)
                    elseif addon.config.debugMode then
                        originalAddMessage(self, string.format("|cff00ff00[GIS Debug]|r Skipped RIP for %s (40%% chance)", playerName))
                    end
                end
            end
        end
        
        return originalAddMessage(self, text, ...)
    end
end

-- Initialization
local function onPlayerLogin()
    LoadSavedVariables()
    HookChatFrame()
    local _, class = UnitClass("player")
    local playerLevel = UnitLevel("player")
    local statusText = addon.config.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
    print(string.format("|cff00ff00[GuildItemScanner]|r Loaded for Level %d %s - Addon is %s. Type /gis for commands.", playerLevel, class, statusText))
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GIS Debug]|r Alert frame initialized at %s, isVisible=%s", 
            alertFrame:GetPoint(1), tostring(alertFrame:IsVisible())))
    end
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